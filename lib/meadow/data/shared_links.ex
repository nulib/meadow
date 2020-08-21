defmodule Meadow.Data.SharedLinks do
  @moduledoc """
  Manage shared links to works
  """

  alias Meadow.Config

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
    ttl = if is_nil(ttl), do: Config.shared_link_ttl(), else: ttl
    expires = DateTime.utc_now() |> DateTime.add(ttl, :millisecond)
    link = %__MODULE__{shared_link_id: Ecto.UUID.generate(), expires: expires, work_id: work_id}

    document = %{
      shared_link_id: link.shared_link_id,
      target_id: link.work_id,
      expires: link.expires,
      target_index: "meadow"
    }

    result =
      Elastix.Document.index(
        elasticsearch_url(),
        @index,
        @type_name,
        link.shared_link_id,
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
end
