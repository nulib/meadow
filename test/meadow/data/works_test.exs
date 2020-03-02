defmodule Meadow.Data.WorksTest do
  use Meadow.DataCase

  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.{FileSets, Works}
  alias Meadow.Repo

  describe "queries" do
    @valid_attrs %{
      accession_number: "12345",
      visibility: "open",
      work_type: "image",
      descriptive_metadata: %{title: "Test"}
    }
    @invalid_attrs %{accession_number: nil}

    test "list_works/0 returns all works" do
      work_fixture()
      assert length(Works.list_works()) == 1
    end

    test "get_works_by_title/1 fetches the works by title" do
      work = work_fixture()
      title = work.descriptive_metadata.title
      assert length(Works.get_works_by_title(title)) == 1
    end

    test "create_work/1 with valid data creates a work" do
      assert {:ok, %Work{} = work} = Works.create_work(@valid_attrs)
    end

    test "create_work/1 with invalid data does not create a work" do
      assert {:error, %Ecto.Changeset{}} = Works.create_work(@invalid_attrs)
    end

    test "create_work!/1 with valid data creates a work" do
      assert %Work{} = Works.create_work!(@valid_attrs)
    end

    test "create_work!/1 with invalid data does not create a work" do
      assert_raise(Ecto.InvalidChangesetError, fn -> Works.create_work!(@invalid_attrs) end)
    end

    test "update_work/2 updates a work" do
      work = work_fixture()

      assert {:ok, %Work{} = work} =
               Works.update_work(work, %{descriptive_metadata: %{title: "New name"}})

      assert work.descriptive_metadata.title == "New name"
    end

    test "update_work/2 with invalid attributes returns an error" do
      work = work_fixture()
      assert {:error, %Ecto.Changeset{}} = Works.update_work(work, %{work_type: "Dictionary"})
    end

    test "delete_work/1 deletes a work" do
      work = work_fixture()
      assert {:ok, %Work{} = work} = Works.delete_work(work)
      assert Enum.empty?(Works.list_works())
    end

    test "get_work!/1 returns a work by id" do
      work = work_fixture()
      assert %Work{} = Works.get_work!(work.id)
    end

    test "accession_exists?/1 returns true if accession is already taken" do
      work = work_fixture()

      assert Works.accession_exists?(work.accession_number) == true
    end

    test "add_to_collection/2 adds the work to a collection" do
      work = work_fixture()

      collection_id =
        collection_fixture()
        |> Map.get(:id)

      assert {:ok, %Work{collection_id: collection_id} = work} =
               Works.add_to_collection(work, collection_id)
    end

    test "add_to_collection/2 with an invalid collection fails" do
      work = work_fixture()

      collection_id = "1234"

      assert {:error, _} = Works.add_to_collection(work, collection_id)
    end

    test "work metadata should default to empty maps" do
      {:ok, work} =
        Works.create_work(%{accession_number: "abc", visibility: "open", work_type: "image"})

      assert work.descriptive_metadata.title == nil
      assert work.administrative_metadata.preservation_level == nil
    end
  end

  describe "representative images" do
    setup do
      work = work_with_file_sets_fixture(3)
      file_set = work.file_sets |> Enum.at(1)

      {:ok, %Work{} = work} = Works.set_representative_image(work, file_set)

      {:ok,
       work: work,
       image_id: file_set.id,
       image_url: Meadow.Config.iiif_server_url() <> file_set.id}
    end

    test "no representative image assigned", %{work: work} do
      {:ok, work} = Works.set_representative_image(work, nil)
      assert(is_nil(work.representative_image))
    end

    test "list_works/0", %{image_url: image_url} do
      [work] = Works.list_works()
      assert(work.representative_image == image_url)
    end

    test "get_work!/1", %{work: work, image_url: image_url} do
      assert(
        Works.get_work!(work.id)
        |> Map.get(:representative_image) == image_url
      )
    end

    test "get_work_by_accession_number!/1", %{work: work, image_url: image_url} do
      assert(
        Works.get_work_by_accession_number!(work.accession_number)
        |> Map.get(:representative_image) == image_url
      )
    end

    test "get_works_by_title/1", %{work: work, image_url: image_url} do
      with title <- work.descriptive_metadata.title do
        [work] = Works.get_works_by_title(title)
        assert(work.representative_image == image_url)
      end
    end

    test "add_representative_image/1 single work", %{work: work, image_url: image_url} do
      work =
        Work
        |> Repo.get!(work.id)
        |> Works.add_representative_image()

      assert work.representative_image == image_url
    end

    test "add_representative_image/1 list of works", %{image_url: image_url} do
      [work] =
        Work
        |> Repo.all()
        |> Works.add_representative_image()

      assert work.representative_image == image_url
    end

    test "add_representative_image/1 stream of works", %{image_url: image_url} do
      stream =
        Work
        |> Repo.stream()
        |> Works.add_representative_image()

      {:ok, [work]} = Repo.transaction(fn -> stream |> Enum.into([]) end)
      assert work.representative_image == image_url
    end

    test "add_representative_image/1 passthrough" do
      assert "Not a work" |> Works.add_representative_image() == "Not a work"
    end

    test "deleting a file set nilifies the representative image", %{
      image_id: image_id,
      image_url: image_url,
      work: work
    } do
      assert(Works.get_work!(work.id) |> Map.get(:representative_image) == image_url)
      FileSets.get_file_set!(image_id) |> FileSets.delete_file_set()
      assert(is_nil(Works.get_work!(work.id) |> Map.get(:representative_image)))
    end
  end
end
