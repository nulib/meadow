defmodule Meadow.MigrationTest do
  use Meadow.MigrationCase

  alias Meadow.Config
  alias Meadow.Data.DonutWorks
  alias Meadow.Data.Schemas.{DonutWork, Work}
  alias Meadow.Migration
  alias Meadow.Repo

  import ExUnit.CaptureLog

  describe "manifests" do
    test "read_manifest/1", %{manifests: [source | _]} do
      with manifest <- Migration.read_manifest(source) do
        assert %{id: _work_id, file_sets: [%{id: _file_set_id} | _]} = manifest
      end
    end

    test "update_file_set_core_metadata/1", %{manifests: [source | _]} do
      manifest = Migration.read_manifest(source)
      original_file_set = manifest |> Map.get(:file_sets) |> List.first()

      updated_file_set =
        manifest
        |> Migration.update_file_set_core_metadata()
        |> Map.get(:file_sets)
        |> List.first()

      assert original_file_set
             |> get_in([:metadata, :location])
             |> String.starts_with?("s3://stack-p-fedora-binaries/")

      assert updated_file_set
             |> get_in([:core_metadata, :location])
             |> String.starts_with?("s3://#{Config.migration_binary_bucket()}/")

      assert updated_file_set |> get_in([:core_metadata, :digests]) |> Map.has_key?(:sha1)
      assert updated_file_set |> get_in([:core_metadata, :digests]) |> Map.has_key?(:sha256)

      assert updated_file_set |> get_in([:core_metadata, :label]) ==
               updated_file_set |> get_in([:core_metadata, :original_filename])

      refute updated_file_set
             |> get_in([:core_metadata, :original_filename])
             |> String.contains?("?")
    end

    test "changeset/1", %{manifests: [source | _]} do
      with changeset <- Migration.read_manifest(source) |> Migration.changeset() do
        assert changeset.valid?
      end
    end
  end

  describe "import/1" do
    test "imports all manifests", %{manifests: manifests} do
      assert Repo.aggregate(DonutWork, :count) == 0
      Migration.import()
      assert Repo.aggregate(DonutWork, :count) == length(manifests)
    end

    test "skips existing DonutWork", %{manifests: [first | _] = manifests} do
      with work_id <- Path.basename(first, ".json") do
        {:ok, _} =
          DonutWorks.create_donut_work(%{
            work_id: work_id,
            manifest: first,
            last_modified: DateTime.utc_now()
          })

        assert capture_log(fn -> Migration.import() end)
               |> String.contains?("Skipping manifest #{first}")

        assert Repo.aggregate(DonutWork, :count) == length(manifests)
      end
    end

    test "skips existing Work", %{manifests: [first | rest]} do
      with work_id <- Path.basename(first, ".json") do
        {:ok, _} =
          Work.migration_changeset(%{id: work_id, accession_number: work_id})
          |> Repo.insert()

        assert capture_log(fn -> Migration.import() end)
               |> String.contains?("Skipping manifest #{first}")

        assert Repo.aggregate(DonutWork, :count) == length(rest)
      end
    end

    test "reinitializes with newer manifest", %{manifests: [first | _]} do
      with work_id <- Path.basename(first, ".json") do
        Migration.import()

        DonutWorks.get_donut_work!(work_id)
        |> DonutWorks.update_donut_work!(%{
          status: "error",
          last_modified: DateTime.utc_now() |> DateTime.add(-3600, :second)
        })

        assert capture_log(fn -> Migration.import() end)
               |> String.contains?("Reinitializing #{first}")
      end
    end
  end

  describe "cache_authorities/0" do
    setup do
      Migration.import()
    end

    test "pre-caches authorities for all manifests" do
      log = capture_log(fn -> Migration.cache_authorities() end)

      %{"count" => count} = Regex.named_captures(~r/Pre-caching (?<count>\d+) unique terms/, log)

      assert Cachex.count!(Meadow.Cache.ControlledTerms) == String.to_integer(count)
    end
  end

  describe "migrate/1" do
    setup do
      Migration.import()
      Migration.cache_authorities()
    end

    test "migrates all manifests", %{manifests: manifests} do
      assert Repo.aggregate(Work, :count) == 0
      log = capture_log(fn -> Migration.migrate(:all) end)
      assert Repo.aggregate(Work, :count) == length(manifests) - 1

      assert log =~
               ~r/Error importing work [0-9a-f-]+: date_created \[%\{edtf: "194x"\}\] is invalid/
    end

    test "migrates some manifests" do
      assert Repo.aggregate(Work, :count) == 0
      log = capture_log(fn -> Migration.migrate(2) end)
      assert Repo.aggregate(Work, :count) == 2

      refute log =~
               ~r/Error importing work/
    end

    test "missing binary", %{manifests: [first | _]} do
      work_attributes =
        first |> Migration.read_manifest() |> Migration.update_file_set_core_metadata()

      [file_set | _] = work_attributes.file_sets
      binary = file_set |> get_in([:core_metadata, :location])
      s3_uri = URI.parse(binary)

      with key <- "/" <> s3_uri.path do
        delete_object(s3_uri.host, key)
      end

      log = capture_log(fn -> Migration.migrate(2) end)
      assert Repo.aggregate(Work, :count) == 1

      expected_error = ~s(Binaries missing: ["#{binary}"])

      assert log |> String.contains?(expected_error)

      with donut_work <- DonutWorks.get_donut_work!(work_attributes.id) do
        assert donut_work.status == "error"
        assert donut_work.error == expected_error
      end
    end
  end
end
