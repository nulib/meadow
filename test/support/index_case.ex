defmodule Meadow.IndexCase do
  @moduledoc """
  This module resets the Elasticsearch index between tests.
  """
  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.Schemas.{Collection, FileSet, IndexTime, Work}
  alias Meadow.ElasticsearchCluster, as: Cluster
  alias Meadow.Repo

  setup tags do
    Elasticsearch.Index.clean_starting_with(Cluster, "meadow", 0)
    Elasticsearch.delete(Cluster, "/meadow")
    Elasticsearch.Index.hot_swap(Cluster, "meadow")

    on_exit(fn ->
      if tags[:unboxed] do
        Sandbox.unboxed_run(Repo, fn ->
          [IndexTime, FileSet, Work, Collection]
          |> Enum.each(fn schema -> Repo.delete_all(schema) end)
        end)
      end
    end)

    :ok
  end

  using do
    quote do
      import Meadow.TestHelpers

      def indexed_doc_count do
        Elasticsearch.get!(Cluster, "/meadow/_count") |> get_in(["count"])
      end

      def indexed_doc(id) do
        Elasticsearch.get!(Cluster, "/meadow/_doc/#{id}") |> get_in(["_source"])
      end

      def decode_njson(data) do
        data |> String.split(~r/\n/) |> Enum.map(&Jason.decode!/1)
      end

      def indexable_data do
        collection = collection_fixture()

        works =
          1..5
          |> Enum.map(fn i ->
            work_fixture(%{
              descriptive_metadata: %{title: "Test Work #{i}"},
              collection_id: collection.id,
              visibility: "restricted",
              published: false
            })
          end)

        file_sets =
          works
          |> Enum.reduce([], fn work, acc ->
            acc ++ Enum.map(1..2, fn _ -> file_set_fixture(%{work_id: work.id}) end)
          end)

        %{
          count: length(works) + length(file_sets) + 1,
          collection: collection,
          works: works,
          file_sets: file_sets
        }
      end
    end
  end
end
