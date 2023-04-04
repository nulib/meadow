defmodule Meadow.FileSetDeleteListenerTest do
  use Meadow.S3Case
  use Meadow.UnsandboxedDataCase, async: false

  alias Ecto.Adapters.SQL
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.UnsandboxedDataCase.Repo

  import Ecto.Changeset
  import ExUnit.CaptureLog

  @ingest_key "waiting/to/ingest.tif"
  @ingest_location "s3://#{@ingest_bucket}/#{@ingest_key}"
  @pairtree "44/87/89/28/-c/4d/e-/40/76/-b/61/3-/15/35/66/5f/fa/e2"
  @poster_key "posters/#{@pairtree}-poster.tif"
  @preservation_key "#{@pairtree}/preservation-file"
  @pyramid_key "#{@pairtree}-pyramid.tif"
  @poster_location "s3://#{@pyramid_bucket}/#{@poster_key}"
  @preservation_location "s3://#{@preservation_bucket}/#{@preservation_key}"
  @pyramid_location "s3://#{@pyramid_bucket}/#{@pyramid_key}"
  @streaming_location "s3://#{@streaming_bucket}/#{@pairtree}"
  @timeout 5000

  def file_set_notification_fixture(index) do
    params = %{
      accession_number: "NOTIFICATION_TEST_FIXTURE_#{index}",
      core_metadata: %{
        location: @preservation_location,
        original_filename: "coffee.tif"
      },
      derivatives: %{
        "pyramid_tiff" => @pyramid_location,
        "poster" => @poster_location,
        "playlist" => "#{@streaming_location}/playlist.m3u8"
      },
      role: %{id: "A", schema: "file_set_role"}
    }

    %FileSet{}
    |> cast(params, [:accession_number, :derivatives, :role])
    |> cast_embed(:core_metadata)
    |> unique_constraint(:accession_number)
    |> Repo.insert!()
  end

  describe "clean_up!/1" do
    @describetag s3: [
                   %{
                     bucket: @ingest_bucket,
                     key: @ingest_key,
                     content: File.read!("test/fixtures/coffee.tif")
                   },
                   %{
                     bucket: @preservation_bucket,
                     key: @preservation_key,
                     content: File.read!("test/fixtures/coffee.tif")
                   },
                   %{
                     bucket: @pyramid_bucket,
                     key: @pyramid_key,
                     content: File.read!("test/fixtures/coffee.tif")
                   },
                   %{
                     bucket: @pyramid_bucket,
                     key: @poster_key,
                     content: File.read!("test/fixtures/coffee.tif")
                   },
                   %{
                     bucket: @streaming_bucket,
                     key: "#{@pairtree}/playlist.m3u8",
                     content: "#EXTM3U\n"
                   },
                   %{
                     bucket: @streaming_bucket,
                     key: "#{@pairtree}/stream_file.m4v",
                     content: File.read!("test/fixtures/small.m4v")
                   }
                 ]

    setup do
      start_supervised!({Meadow.FilesetDeleteListener, repo: Repo, notify: self()})
      on_exit(fn -> FileSet |> Repo.delete_all() end)
      {:ok, %{file_set: file_set_notification_fixture(1)}}
    end

    test "derivatives deleted", %{file_set: file_set} do
      with file_set_id <- file_set.id do
        Repo.delete(file_set)
        assert_receive {"cleaned", ^file_set_id}, @timeout
        refute object_exists?(@pyramid_bucket, @pyramid_key)
        refute object_exists?(@pyramid_bucket, @poster_key)
        refute object_exists?(@streaming_bucket, "#{@pairtree}/playlist.m3u8")
        refute object_exists?(@streaming_bucket, "#{@pairtree}/stream_file.m4v")
      end
    end

    test "preservation file deleted", %{file_set: file_set} do
      with file_set_id <- file_set.id do
        Repo.delete(file_set)
        assert_receive {"cleaned", ^file_set_id}, @timeout
        refute object_exists?(@preservation_bucket, @preservation_key)
      end
    end

    @tag :skip
    test "preservation file retained if other file sets refer to it", %{file_set: last_file_set} do
      file_sets = Enum.map(2..3, &file_set_notification_fixture/1)

      file_sets
      |> Enum.each(fn file_set ->
        with file_set_id <- file_set.id do
          Repo.delete(file_set)
          assert_receive {"cleaned", ^file_set_id}, @timeout
          assert object_exists?(@preservation_bucket, @preservation_key)
        end
      end)

      with file_set_id <- last_file_set.id do
        Repo.delete(last_file_set)
        assert_receive {"cleaned", ^file_set_id}, @timeout
        refute object_exists?(@preservation_bucket, @preservation_key)
      end
    end

    test "file retained if it's in the ingest bucket", %{file_set: file_set} do
      with %{id: file_set_id} <- file_set do
        file_set
        |> FileSet.update_changeset(%{core_metadata: %{location: @ingest_location}})
        |> Repo.update!()
        |> Repo.delete()

        assert_receive {"cleaned", ^file_set_id}, @timeout
        assert object_exists?(@ingest_bucket, @ingest_key)
      end
    end

    @tag :skip
    test "bulk delete", %{file_set: file_set} do
      file_sets = [file_set | Enum.map(2..10, &file_set_notification_fixture/1)]
      SQL.query!(Repo, "DELETE FROM file_sets")
      Enum.each(file_sets, fn %{id: id} -> assert_receive {"cleaned", ^id}, @timeout end)
      refute object_exists?(@preservation_bucket, @preservation_key)
    end

    @tag :skip
    test "logging", %{file_set: file_set} do
      extra_file_set = file_set_notification_fixture(2)

      log =
        capture_log(fn ->
          with id <- extra_file_set.id do
            Repo.delete(extra_file_set)
            assert_receive {"cleaned", ^id}, @timeout
          end
        end)

      [
        "Cleaning up assets for file set #{extra_file_set.id}",
        "Removing streaming files from #{@streaming_location}/",
        "Removing poster derivative at #{@poster_location}",
        "Removing pyramid_tiff derivative at #{@pyramid_location}",
        "Leaving #{@preservation_location} intact: 1 additional reference"
      ]
      |> Enum.each(fn line -> assert String.match?(log, ~r/\[warn(ing)?\]\s+#{line}/) end)

      log =
        capture_log(fn ->
          with id <- file_set.id do
            Repo.delete(file_set)
            assert_receive {"cleaned", ^id}, @timeout
          end
        end)

      [
        "Cleaning up assets for file set #{file_set.id}",
        "Removing streaming files from #{@streaming_location}/",
        "Removing poster derivative at #{@poster_location}",
        "Removing pyramid_tiff derivative at #{@pyramid_location}",
        "Removing preservation file at #{@preservation_location}"
      ]
      |> Enum.each(fn line -> assert String.match?(log, ~r/\[warn(ing)?\]\s+#{line}/) end)
    end
  end
end
