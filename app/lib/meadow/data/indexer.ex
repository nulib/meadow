defmodule Meadow.Data.Indexer do
  @moduledoc """
  Indexes individual structs into our search indexes, preloading if necessary.
  """
  use Meadow.Utils.Logging

  alias Meadow.Repo
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Search.Bulk
  alias Meadow.Search.Client, as: SearchClient
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.Document, as: SearchDocument
  alias Meadow.Search.Index, as: SearchIndex

  require Logger

  import Ecto.Query

  def reindex_all do
    SearchConfig.index_versions()
    |> Enum.each(&reindex_all/1)
  end

  def reindex_all(version) do
    reindex_all(version, [Collection, Work, FileSet])
  end

  def reindex_all(version, schemas) when is_list(schemas) do
    schemas
    |> Enum.uniq()
    |> Enum.each(&reindex_all(version, &1))
  end

  def reindex_all(version, schema) do
    SearchClient.hot_swap(schema, version, fn index ->
      synchronize_schema(schema, version, index, :all)
      |> check_synchronize_result(schema, index)
    end)
  end

  def check_synchronize_result(:ok, schema, index) do
    expected = Repo.aggregate(schema, :count)

    case SearchClient.indexed_doc_count(index) do
      {:ok, count} ->
        if count < expected * 0.9 do
          error = Meadow.IndexerError.exception("Indexed #{count} docs; expected #{expected}")
          {:incomplete, error}
        else
          :ok
        end

      {:error, reason} ->
        {:incomplete, reason}
    end
  end

  def check_synchronize_result(other, _, _), do: other

  def synchronize_index do
    SearchConfig.index_versions()
    |> Enum.each(&synchronize_index/1)
  end

  def synchronize_index(version) do
    [FileSet, Work, Collection]
    |> Enum.each(&synchronize_schema(&1, version))
  end

  def synchronize_schema(schema, version) do
    with index <- SearchConfig.alias_for(schema, version),
         {:ok, since} <- SearchClient.most_recent(index) do
      synchronize_schema(schema, version, index, since)
    end
  end

  def synchronize_schema(schema, version, index, :all) do
    preloads = schema.required_index_preloads()

    from(schema)
    |> stream(preloads)
    |> maybe_add_representative_image(schema)
    |> synchronize_schema(version, index)
  end

  def synchronize_schema(schema, version, index, since) do
    preloads = schema.required_index_preloads()

    from(s in schema,
      where: s.updated_at >= ^since
    )
    |> stream(preloads)
    |> maybe_add_representative_image(schema)
    |> synchronize_schema(version, index)
  end

  def synchronize_schema(stream, version, index) do
    Repo.transaction(
      fn ->
        stream
        |> Stream.map(&encode_document(&1, version))
        |> Stream.reject(&(&1 == :skip))
        |> Bulk.upload(index)

        SearchIndex.refresh(index)
        :ok
      end,
      timeout: :infinity
    )
  end

  defp encode_document(nil, _), do: :skip

  defp encode_document(item, version) do
    SearchDocument.encode(item, version)
  rescue
    e ->
      with_log_metadata module: __MODULE__, id: item.id do
        ("Index encoding failed due to: " <> Exception.format_banner(:error, e, []))
        |> Logger.error()
      end

      :skip
  end

  def stream(query, preloads) do
    from(query)
    |> Repo.stream()
    |> Stream.chunk_every(10)
    |> Stream.flat_map(&Repo.preload(&1, preloads))
  end

  def maybe_add_representative_image(stream, Collection),
    do: Stream.map(stream, &Collections.add_representative_image/1)

  def maybe_add_representative_image(stream, Work),
    do: Stream.map(stream, &Works.add_representative_image/1)

  def maybe_add_representative_image(stream, _), do: stream
end
