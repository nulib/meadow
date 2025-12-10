defmodule Meadow.Search.Slice do
  @moduledoc """
  Functions for performing sliced point-in-time OpenSearch queries.
  """

  alias Meadow.Search.HTTP

  @default_slice_size 7_500

  defstruct [:query, :index, :pit_id, max_slices: 1]

  @doc """
  Paginate a query by adding slicing information.
  """
  def paginate(query, index, slice_size \\ @default_slice_size)

  def paginate(query, index, slice_size) when is_binary(query) do
    case Jason.decode(query) do
      {:ok, decoded} -> paginate(decoded, index, slice_size)
      error -> error
    end
  end

  def paginate(query, index, slice_size) do
    %__MODULE__{query: query, index: index}
    |> add_slice_count(slice_size)
    |> paginate_query()
  end

  @doc """
  Retrieve a specific slice of results.
  """
  def slice(%{max_slices: max}, slice_number) when slice_number < 0 or slice_number >= max,
    do: {:error, "Slice number (#{slice_number}) must be between 0 and #{max - 1}"}

  def slice(%{query: query, max_slices: max_slices} = struct, slice_number) when max_slices > 1 do
    %__MODULE__{struct | query: Map.put(query, :slice, %{id: slice_number, max: max_slices})}
    |> slice()
  end

  def slice(%{query: query, index: index}, _slice_number) do
    HTTP.post([index, "_search"], query)
    |> extract_hits()
  end

  def slice(%{pit_id: pit_id, query: query}) do
    query =
      Map.put(query, :pit, %{id: pit_id, keep_alive: "5m"})

    HTTP.post(["_search"], query)
    |> extract_hits()
  end

  @doc """
  Finish the slice by deleting the point-in-time context.
  """
  def finish(%{pit_id: pit_id}) when is_binary(pit_id) do
    HTTP.request(:delete, ["_search", "point_in_time"], %{pit_id: [pit_id]})
    :ok
  end

  defp add_slice_count(%{query: query, index: index} = struct, slice_size) do
    query =
      Enum.map(query, fn
        {"query", value} -> {"query", value}
        {:query, value} -> {"query", value}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{})

    case get_count(index, query) do
      {:ok, count} -> {:ok, %__MODULE__{struct | max_slices: div(count, slice_size) + 1}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_count(index, %{"query" => _} = query) do
    case HTTP.post([index, "_count"], query) do
      {:ok, %{body: %{"count" => count}}} -> {:ok, count}
      {:ok, %{body: body}} -> {:error, body}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_count(_, _), do: {:error, "Query must contain a 'query' field"}

  defp paginate_query({:ok, %{index: index} = struct}) do
    case create_pit(index) do
      {:ok, pit_id} -> %__MODULE__{struct | pit_id: pit_id}
      _ -> struct
    end
  end

  defp paginate_query(other), do: other

  defp create_pit(index) do
    case HTTP.post([index, "_search", "point_in_time?keep_alive=5m"]) do
      {:ok, %{body: %{"pit_id" => pit_id}}} -> {:ok, pit_id}
      _ -> :error
    end
  end

  defp extract_hits({:ok, %{body: %{"hits" => %{"hits" => hits}}}}), do: {:ok, hits}
  defp extract_hits({:ok, %{body: body}}), do: {:error, body}
  defp extract_hits({:error, reason}), do: {:error, reason}
end
