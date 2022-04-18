defmodule Meadow.IndexCase do
  @moduledoc """
  This module resets the Elasticsearch index between tests.
  """
  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Data.Schemas.{Collection, FileSet, IndexTime, Work}
  alias Meadow.ElasticsearchCluster, as: Cluster
  alias Meadow.Ingest.Schemas.{Project, Sheet}
  alias Meadow.Repo

  @meadow_index Meadow.Config.elasticsearch_index()

  setup tags do
    Elasticsearch.Index.clean_starting_with(Cluster, "#{@meadow_index}", 0)
    Elasticsearch.delete(Cluster, "/#{@meadow_index}")
    Elasticsearch.Index.hot_swap(Cluster, "#{@meadow_index}")

    on_exit(fn ->
      if tags[:unboxed] do
        Sandbox.unboxed_run(Repo, fn ->
          [IndexTime, FileSet, Sheet, Project, Work, Collection]
          |> Enum.each(fn schema -> Repo.delete_all(schema) end)
        end)
      end
    end)

    :ok
  end

  using do
    quote do
      import Meadow.{IndexCase, TestHelpers}

      @meadow_index unquote(@meadow_index)

      def indexed_doc_count do
        Elasticsearch.get!(Cluster, "/#{@meadow_index}/_count") |> get_in(["count"])
      end

      def indexed_doc(id) do
        Elasticsearch.get!(Cluster, "/#{@meadow_index}/_doc/#{id}") |> get_in(["_source"])
      end

      def decode_njson(data) do
        data |> String.split(~r/\n/) |> Enum.map(&Jason.decode!/1)
      end

      def project_sheet_and_work do
        project = project_fixture()

        ingest_sheet =
          ingest_sheet_fixture(%{
            project_id: project.id,
            title: "sheet title",
            filename: "sheet_name.csv"
          })

        %{works: [work | _]} = indexable_data()
        work |> Works.update_work(%{collection_id: nil, ingest_sheet_id: ingest_sheet.id})

        {project, ingest_sheet, work}
      end

      def indexable_data do
        collection = collection_fixture() |> Collections.add_representative_image()

        works =
          1..5
          |> Enum.map(fn i ->
            work_fixture(%{
              descriptive_metadata: %{title: "Test Work #{i}"},
              collection_id: collection.id,
              published: false
            })
          end)
          |> Works.add_representative_image()

        file_sets =
          works
          |> Enum.reduce([], fn work, acc ->
            acc ++ Enum.map(1..2, fn _ -> file_set_fixture(%{work_id: work.id}) end)
          end)

        %{
          count: length(works) + length(file_sets) + 1,
          collection: collection,
          works: Works.list_works(),
          file_sets: file_sets
        }
      end
    end
  end
end
