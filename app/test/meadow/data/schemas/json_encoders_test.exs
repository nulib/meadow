defmodule Meadow.Data.Schemas.JSONEncodersTest do
  use Meadow.DataCase

  alias Meadow.Data.Works
  alias Meadow.Repo

  setup do
    collection = collection_fixture()
    project = project_fixture()
    ingest_sheet = ingest_sheet_fixture(%{project_id: project.id})
    work = work_fixture(%{collection_id: collection.id, ingest_sheet_id: ingest_sheet.id})
    work = Works.get_work!(work.id) |> Meadow.Repo.preload([:project, :collection])

    {:ok, %{collection: collection, work: work}}
  end

  describe "JSON.Encoder" do
    test "JSON encoding of Work schema without FileSets", %{work: work} do
      encoded = JSON.encode!(work)
      decoded = JSON.decode!(encoded)

      assert decoded["id"] == work.id
      assert get_in(decoded, ["descriptive_metadata", "title"]) == work.descriptive_metadata.title

      # NotLoaded associations should be encoded as nil or empty list, not causing errors
      assert decoded["file_sets"] == []
      assert decoded["ingest_sheet"] == nil
      # Loaded associations with proper encoders should be encoded as their JSON representation
      assert decoded["collection"]["id"] == work.collection.id
      # Loaded associations without proper encoders should be encoded as nil
      assert decoded["project"] == nil
    end

    test "JSON encoding of Work schema with FileSets", %{work: work} do
      Enum.each(1..5, fn _ -> file_set_fixture(%{work_id: work.id}) end)
      work = Repo.preload(work, [:file_sets])

      encoded = JSON.encode!(work)
      decoded = JSON.decode!(encoded)

      assert decoded["id"] == work.id
      assert get_in(decoded, ["descriptive_metadata", "title"]) == work.descriptive_metadata.title

      # NotLoaded associations should be encoded as nil or empty list, not causing errors
      assert decoded["ingest_sheet"] == nil
      # Loaded associations with proper encoders should be encoded as their JSON representation
      assert decoded["collection"]["id"] == work.collection.id
      assert decoded["file_sets"] |> length() == work.file_sets |> length()
      # Loaded associations without proper encoders should be encoded as nil
      assert decoded["project"] == nil
    end
  end

  describe "Jason.Encoder" do
    test "Jason encoding of Work schema without FileSets", %{work: work} do
      encoded = Jason.encode!(work)
      decoded = Jason.decode!(encoded)

      assert decoded["id"] == work.id
      assert get_in(decoded, ["descriptive_metadata", "title"]) == work.descriptive_metadata.title

      # NotLoaded associations should be encoded as nil or empty list, not causing errors
      assert decoded["file_sets"] == []
      assert decoded["ingest_sheet"] == nil
      # Loaded associations with proper encoders should be encoded as their JSON representation
      assert decoded["collection"]["id"] == work.collection.id
      # Loaded associations without proper encoders should be encoded as nil
      assert decoded["project"] == nil
    end

    test "Jason encoding of Work schema with FileSets", %{work: work} do
      Enum.each(1..5, fn _ -> file_set_fixture(%{work_id: work.id}) end)
      work = Repo.preload(work, [:file_sets])

      encoded = Jason.encode!(work)
      decoded = Jason.decode!(encoded)

      assert decoded["id"] == work.id
      assert get_in(decoded, ["descriptive_metadata", "title"]) == work.descriptive_metadata.title

      # NotLoaded associations should be encoded as nil or empty list, not causing errors
      assert decoded["ingest_sheet"] == nil
      # Loaded associations with proper encoders should be encoded as their JSON representation
      assert decoded["collection"]["id"] == work.collection.id
      assert decoded["file_sets"] |> length() == work.file_sets |> length()
      # Loaded associations without proper encoders should be encoded as nil
      assert decoded["project"] == nil
    end
  end
end
