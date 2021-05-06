defmodule Meadow.Data.SharedLinks do
  @moduledoc """
  Manage shared links to works
  """

  alias Meadow.Config
  alias Meadow.Utils.ElasticsearchResultStream
  alias NimbleCSV.RFC4180, as: CSV

  @index "shared_links"
  @type_name "_doc"

  @enforce_keys [:work_id, :expires]
  defstruct shared_link_id: nil, work_id: nil, expires: nil

  @doc """
  Generate a shared link for a work

  ## Examples:

      iex> generate("61f5c14c-04f6-4e5a-ab08-6e94b34d0842")
      {:ok,
      %{
        expires: ~U[2020-08-28 16:54:21.802770Z],
        id: "5e26b120-601d-4b50-8154-60ead9837568"
      }}
  """
  def generate(work_id, ttl \\ nil) do
    with link <- shared_link(work_id, ttl),
         document <- shared_link_document(link) do
      result =
        Elastix.Document.index(
          elasticsearch_url(),
          @index,
          @type_name,
          document.shared_link_id,
          document
        )

      Elastix.Index.refresh(elasticsearch_url(), @index)

      case result do
        {:ok, %{status_code: 200}} -> {:ok, link}
        {:ok, %{status_code: 201}} -> {:ok, link}
        {:ok, %{body: body}} -> {:error, body}
        {:error, %{reason: reason}} -> {:error, reason}
      end
    end
  end

  def generate_many(query, ttl \\ nil)

  def generate_many(query, ttl) when is_binary(query) do
    docs =
      query
      |> ElasticsearchResultStream.results()
      |> Stream.map(fn %{"_source" => work_doc} ->
        case work_doc do
          %{"visibility" => %{"id" => "OPEN"}, "published" => true} ->
            {shared_link_row(work_doc, work_doc["id"], nil, "items"), nil}

          _ ->
            with doc <- shared_link(work_doc["id"], ttl) |> shared_link_document(),
                 row <- shared_link_row(work_doc, doc.shared_link_id, doc.expires, "shared") do
              {row, doc}
            end
        end
      end)
      |> Enum.to_list()

    bulk_payload =
      docs
      |> Enum.reject(fn {_, doc} -> is_nil(doc) end)
      |> Enum.reduce([], fn
        {_, doc}, lines ->
          [%{index: %{_id: doc.shared_link_id}} | [doc | lines]]
      end)

    case create_shared_link_docs(bulk_payload) do
      :noop ->
        csv_result(docs)

      {:ok, %{status_code: status}} when status in 200..204 ->
        Elastix.Index.refresh(elasticsearch_url(), @index)
        csv_result(docs)

      {:ok, %{body: body}} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def generate_many(query, ttl), do: generate_many(Jason.encode!(query), ttl)

  defp csv_result(docs) do
    [
      ["work_id", "title", "description", "expires", "shared_link"]
      | docs |> Enum.map(fn {row, _} -> row end)
    ]
    |> CSV.dump_to_stream()
  end

  defp create_shared_link_docs([]), do: :noop

  defp create_shared_link_docs(payload) do
    Elastix.Bulk.post(elasticsearch_url(), payload, index: @index, type: @type_name)
  end

  @doc """
  Revoke a shared link

  ## Examples:

      iex> revoke("5e26b120-601d-4b50-8154-60ead9837568")
      :ok
  """
  def revoke(id) do
    result = Elastix.Document.delete(elasticsearch_url(), @index, @type_name, id)
    Elastix.Index.refresh(elasticsearch_url(), @index)

    case result do
      {:ok, %{status_code: 200}} -> :ok
      {:ok, %{status_code: 404}} -> 0
      {:ok, %{body: body}} -> {:error, body}
      {:error, %{reason: reason}} -> {:error, reason}
    end
  end

  @doc """
  Delete all expired shared links

  ## Examples

      iex> delete_expired()
      {:ok, 1}
  """
  def delete_expired do
    query = %{query: %{range: %{expires: %{lt: "now"}}}}

    result = Elastix.Document.delete_matching(elasticsearch_url(), @index, query)
    Elastix.Index.refresh(elasticsearch_url(), @index)

    case result do
      {:ok, %{status_code: 200, body: %{"deleted" => count}}} -> {:ok, count}
      {:ok, %{body: body}} -> {:error, body}
      {:error, %{reason: reason}} -> {:error, reason}
    end
  end

  @doc """
  Count number of existing shared links

  ## Examples

      iex> count()
      1
  """
  def count do
    case Elastix.Search.count(elasticsearch_url(), @index, [@type_name], %{
           query: %{match_all: %{}}
         }) do
      {:ok, %{body: %{"error" => %{"reason" => "no such index"}}}} -> 0
      {:ok, %{body: %{"count" => count}}} -> count
      {:ok, %{body: body}} -> {:error, body}
    end
  end

  defp elasticsearch_url do
    Application.get_env(:meadow, Meadow.ElasticsearchCluster) |> Keyword.get(:url)
  end

  defp shared_link(work_id, ttl) do
    ttl = if is_nil(ttl), do: Config.shared_link_ttl(), else: ttl
    expires = DateTime.utc_now() |> DateTime.add(ttl, :millisecond)
    %__MODULE__{shared_link_id: Ecto.UUID.generate(), expires: expires, work_id: work_id}
  end

  defp shared_link_document(link) do
    %{
      shared_link_id: link.shared_link_id,
      target_id: link.work_id,
      expires: link.expires,
      target_index: "meadow"
    }
  end

  defp shared_link_row(work_doc, link_id, expires, type) do
    with base_uri <- Config.digital_collections_url() |> URI.parse() do
      [
        work_doc |> get_in(["id"]),
        work_doc |> get_in(["descriptiveMetadata", "title"]),
        (work_doc |> get_in(["descriptiveMetadata", "description"]) || []) |> List.first(),
        expires,
        base_uri |> URI.merge("#{type}/#{link_id}") |> URI.to_string()
      ]
    end
  end
end
