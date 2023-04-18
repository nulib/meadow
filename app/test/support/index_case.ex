defmodule Meadow.IndexCase do
  @moduledoc """
  This module resets the search cluster between tests.
  """
  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Config
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Ingest.Schemas.{Project, Sheet}
  alias Meadow.Repo
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.{Alias, HTTP, Index}

  setup tags do
    result =
      SearchConfig.index_configs()
      |> Enum.map(fn %{name: alias, schemas: [schema | _], version: version} ->
        {:ok, {alias, index}} = Index.create_from_schema(schema, version)
        Alias.update(alias, index)
        {alias, index}
      end)

    Index.clean(Config.shared_links_index(), 0)

    on_exit(fn ->
      if tags[:unboxed] do
        Sandbox.unboxed_run(Repo, fn ->
          [FileSet, Sheet, Project, Work, Collection]
          |> Enum.each(fn schema -> Repo.delete_all(schema) end)
        end)
      end

      Enum.each(result, fn {alias, index} ->
        Alias.remove(alias, [index])
        Index.delete(index)
      end)
    end)

    :ok
  end

  using do
    quote do
      alias Meadow.Search.Client, as: SearchClient
      import Meadow.{IndexCase, TestHelpers}

      def indexed_doc_count(schema, version), do: SearchClient.indexed_doc_count(schema, version)
      def indexed_doc_count(index), do: SearchClient.indexed_doc_count(index)

      def indexed_doc(schema, version, id) do
        SearchConfig.alias_for(schema, version)
        |> indexed_doc(id)
      end

      def indexed_doc(index, id) do
        HTTP.get!("/#{index}/_doc/#{id}") |> Map.from_struct() |> get_in([:body, "_source"])
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

        1..5
        |> Enum.each(fn i ->
          work_fixture(%{
            descriptive_metadata: %{title: "Test Work #{i}"},
            collection_id: collection.id,
            published: false
          })
        end)

        works = Works.list_works()

        file_sets =
          works
          |> Enum.reduce([], fn work, acc ->
            acc ++ Enum.map(1..2, fn _ -> file_set_fixture(%{work_id: work.id}) end)
          end)

        %{
          work_count: length(works),
          file_set_count: length(file_sets),
          collection_count: 1,
          total_count: length(works) + length(file_sets) + 1,
          collection: collection,
          works: works,
          file_sets: file_sets
        }
      end

      def assert_all_empty do
        %{total_count: 0, work_count: 0, file_set_count: 0, collection_count: 0}
        |> assert_doc_counts_match()
      end

      def assert_doc_counts_match(expected) do
        counts = [
          indexed_doc_count(Work, 2),
          indexed_doc_count(FileSet, 2),
          indexed_doc_count(Collection, 2)
        ]

        total_count =
          {:ok,
           counts
           |> Enum.map(&elem(&1, 1))
           |> Enum.reduce(0, &(&1 + &2))}

        context = %{
          total_count: total_count,
          work_count: indexed_doc_count(Work, 2),
          file_set_count: indexed_doc_count(FileSet, 2),
          collection_count: indexed_doc_count(Collection, 2)
        }

        Enum.each(context, fn {key, value} -> assert {:ok, Map.get(expected, key)} == value end)
      end
    end
  end
end
