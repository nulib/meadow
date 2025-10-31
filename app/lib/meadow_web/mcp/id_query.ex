defmodule MeadowWeb.MCP.IDQuery do
  @moduledoc """
  Return a list of Work IDs matching a given OpenSearch query.
  """

  use Anubis.Server.Component,
    type: :tool,
    name: "id_query",
    mime_type: "application/json"

  alias Anubis.Server.Response
  alias Meadow.Data.Schemas.Work
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.Slice
  require Logger

  schema do
    field(:query, :string, description: "The OpenSearch query string.")
  end

  def name, do: "id_query"

  @impl true
  def execute(request, frame) do
    Map.get(request, :query)
    |> add_size_and_source()
    |> Slice.paginate(SearchConfig.alias_for(Work, 2))
    |> fetch_ids(frame)
  end

  defp fetch_ids({:error, reason}, frame) do
    {:reply, Response.tool() |> Response.error(format_reason(reason)), frame}
  end

  defp fetch_ids(slice, frame) do
    ids =
      0..(slice.max_slices - 1)
      |> Enum.chunk_every(10)
      |> Enum.flat_map(fn chunk -> fetch_chunk(chunk, slice) end)

    {:reply, Response.tool() |> Response.json(%{ids: ids}), frame}
  after
    Slice.finish(slice)
  end

  defp add_size_and_source(query) do
    update_source(query, %{
      _source: false,
      fields: [],
      stored_fields: [],
      size: 10_000
    })
  end

  defp fetch_chunk(chunk, slice) do
    chunk
    |> Enum.map(&Task.async(fn -> fetch_slice(slice, &1) end))
    |> Enum.map(&Task.await(&1, 30_000))
    |> List.flatten()
  end

  def fetch_slice(slice, slice_number) do
    case Slice.slice(slice, slice_number) do
      {:ok, hits} ->
        Enum.map(hits, fn %{"_id" => id} -> id end)

      {:error, reason} ->
        Logger.error("Error retrieving slice #{slice_number}: #{inspect(reason)}")
        []
    end
  end

  defp update_source(query, merge) when is_binary(query),
    do: Jason.decode!(query) |> update_source(merge)

  defp update_source(query, merge) do
    Map.merge(query, merge)
  end

  defp format_reason(reason) when is_binary(reason), do: reason
  defp format_reason(reason), do: inspect(reason)
end
