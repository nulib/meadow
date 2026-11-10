defmodule Meadow.Events.Works.EmbeddingsTest do
  use Meadow.DataCase, async: false

  import Assertions

  alias Meadow.Data.{Collections, Works}
  alias Meadow.Embeddings
  alias Meadow.Embeddings.Model.Stub
  alias Meadow.Embeddings.Worker
  alias Meadow.Events.Works.Embeddings, as: EmbeddingEvents

  describe "affected_work_ids/1" do
    test "a new work" do
      assert EmbeddingEvents.affected_work_ids(%{
               type: :insert,
               name: :works,
               new_record: %{id: "work"}
             }) == ["work"]
    end

    test "a work that moved to another collection" do
      event = %{type: :update, name: :works, new_record: %{id: "work"}}

      assert EmbeddingEvents.affected_work_ids(
               Map.put(event, :changes, %{collection_id: %{old_value: nil, new_value: "c"}})
             ) == ["work"]

      assert EmbeddingEvents.affected_work_ids(
               Map.put(event, :changes, %{published: %{old_value: false, new_value: true}})
             ) == []
    end

    test "changes to a work's metadata rows" do
      for table <- Meadow.Events.Indexing.work_metadata_tables() do
        assert EmbeddingEvents.affected_work_ids(%{
                 type: :update,
                 name: table,
                 new_record: %{work_id: "work"}
               }) == ["work"]

        assert EmbeddingEvents.affected_work_ids(%{
                 type: :delete,
                 name: table,
                 old_record: %{work_id: "work"}
               }) == ["work"]
      end
    end

    test "unrelated tables" do
      for name <- [:file_sets, :work_embeddings, :file_set_annotations] do
        assert EmbeddingEvents.affected_work_ids(%{
                 type: :update,
                 name: name,
                 new_record: %{id: "id", work_id: "work"},
                 changes: %{}
               }) == []
      end
    end

    test "a retitled collection affects all of its works" do
      collection = collection_fixture()
      work = work_fixture(%{collection_id: collection.id})
      _other = work_fixture()
      event = %{type: :update, name: :collections, new_record: %{id: collection.id}}

      assert EmbeddingEvents.affected_work_ids(
               Map.put(event, :changes, %{title: %{old_value: "a", new_value: "b"}})
             ) == [work.id]

      assert EmbeddingEvents.affected_work_ids(
               Map.put(event, :changes, %{description: %{old_value: "a", new_value: "b"}})
             ) == []
    end
  end

  describe "database events" do
    @describetag walex: [Meadow.Events.Works.Embeddings]

    setup do
      start_supervised!(Stub)
      start_supervised!({Worker, interval: 50})
      {:ok, work: work_fixture(%{descriptive_metadata: %{title: "Original title"}})}
    end

    defp assert_embedded(work, fun) do
      assert_async(timeout: 5000, sleep_time: 100) do
        assert %{} = embedding = Embeddings.get_work_embedding(work.id)
        assert fun.(embedding)
      end
    end

    test "a new work is embedded", %{work: work} do
      assert_embedded(work, &(&1.model == "embeddinggemma-2"))
      assert Enum.any?(Stub.prompts(), &(&1 =~ "title: Original title | text: "))
    end

    test "a metadata change replaces the embedding", %{work: work} do
      assert_embedded(work, & &1)
      %{text_hash: original} = Embeddings.get_work_embedding(work.id)

      Works.get_work!(work.id)
      |> Works.update_work!(%{descriptive_metadata: %{title: "Changed title"}})

      assert_embedded(work, &(&1.text_hash != original))
      assert Enum.any?(Stub.prompts(), &(&1 =~ "title: Changed title | text: "))
    end

    test "retitling a collection re-embeds its works", %{work: work} do
      collection = collection_fixture(%{title: "Old collection"})
      Works.get_work!(work.id) |> Works.update_work!(%{collection_id: collection.id})
      assert_embedded(work, fn _ -> Enum.any?(Stub.prompts(), &(&1 =~ "Old collection")) end)

      {:ok, _} = Collections.update_collection(collection, %{title: "New collection"})
      assert_embedded(work, fn _ -> Enum.any?(Stub.prompts(), &(&1 =~ "New collection")) end)
    end

    test "a change that does not affect the text is not embedded again", %{work: work} do
      assert_embedded(work, & &1)
      count = length(Stub.prompts())

      Works.get_work!(work.id) |> Works.update_work!(%{published: true})
      Works.get_work!(work.id) |> Works.update_work!(%{descriptive_metadata: %{title: "Second"}})

      assert_embedded(work, fn _ -> Enum.any?(Stub.prompts(), &(&1 =~ "Second")) end)
      assert length(Stub.prompts()) == count + 1
    end
  end
end
