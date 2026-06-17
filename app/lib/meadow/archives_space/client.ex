defmodule Meadow.ArchivesSpace.Client do
  @moduledoc """
  Req-based client for the ArchivesSpace staff API

  Handles session-based authentication: a session token is obtained from
  `POST /users/:user/login`, cached, sent on every request via the
  `X-ArchivesSpace-Session` header, and refreshed automatically when the
  API reports it gone or expired (HTTP 412).
  """

  alias Meadow.Config

  require Logger

  @session_cache_key :archives_space_session
  @session_ttl :timer.minutes(30)

  def get(path, opts \\ []), do: request(:get, path, opts)
  def post(path, opts \\ []), do: request(:post, path, opts)
  def delete(path, opts \\ []), do: request(:delete, path, opts)

  def request(method, path, opts) do
    with {:ok, token} <- session_token() do
      case do_request(method, path, opts, token) do
        {:ok, %{status: 412}} -> retry_with_fresh_session(method, path, opts)
        other -> other
      end
    end
  end

  defp retry_with_fresh_session(method, path, opts) do
    invalidate_session()

    with {:ok, token} <- session_token() do
      do_request(method, path, opts, token)
    end
  end

  @doc "Fetches a record by its ArchivesSpace URI"
  def get_record(uri) do
    case get(uri) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      other -> error(other)
    end
  end

  @doc """
  Updates a record by POSTing its full JSON representation back to its URI

  Returns `{:error, :conflict}` when the record was modified since it was
  fetched (ArchivesSpace optimistic locking on `lock_version`).
  """
  def update_record(uri, %{} = record) do
    case post(uri, json: record) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: 409}} -> {:error, :conflict}
      other -> error(other)
    end
  end

  @doc """
  Creates a record, returning the URI of the new record

  When ArchivesSpace rejects the record as a duplicate of an existing one
  (e.g. a subject with the same terms), returns the existing record's URI
  as `{:conflict, uri}`.
  """
  def create_record(path, %{} = record) do
    case post(path, json: record) do
      {:ok, %{status: 200, body: %{"uri" => uri}}} ->
        {:ok, uri}

      {:ok, %{status: 400, body: %{"error" => %{"conflicting_record" => [uri | _]}}}} ->
        {:conflict, uri}

      other ->
        error(other)
    end
  end

  @doc """
  Searches ArchivesSpace resources (finding aids) by keyword

  ArchivesSpace does not surface parent resources when the keyword only
  matches a child archival object, so the search includes both record types
  and normalizes archival-object hits back to their parent resource.

  Returns `{:ok, %{results: [%{uri: ..., title: ..., identifier: ...}], total_hits: n}}`.
  """
  def search_resources(query, page \\ 1) do
    case get("/search",
           params: [
             {:q, query},
             {:page, page},
             {:"type[]", "resource"},
             {:"type[]", "archival_object"}
           ]
         ) do
      {:ok, %{status: 200, body: %{"results" => results}}} ->
        hits =
          results
          |> Enum.map(&resource_search_hit/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq_by(& &1.uri)

        {:ok,
         %{
           results: hits,
           total_hits: length(hits)
         }}

      other ->
        error(other)
    end
  end

  defp resource_search_hit(%{"primary_type" => "resource"} = result), do: search_hit(result)

  defp resource_search_hit(%{"jsonmodel_type" => "resource"} = result), do: search_hit(result)

  defp resource_search_hit(%{"primary_type" => "archival_object"} = result) do
    result
    |> archival_object_resource_uri()
    |> resource_search_hit_from_uri()
  end

  defp resource_search_hit(%{"jsonmodel_type" => "archival_object"} = result) do
    result
    |> archival_object_resource_uri()
    |> resource_search_hit_from_uri()
  end

  defp resource_search_hit(_result), do: nil

  defp resource_search_hit_from_uri(nil), do: nil

  defp resource_search_hit_from_uri(uri) do
    case get_record(uri) do
      {:ok, resource} ->
        search_hit(resource)

      {:error, reason} ->
        Logger.warning("Could not load ArchivesSpace resource #{uri}: #{inspect(reason)}")
        nil
    end
  end

  defp archival_object_resource_uri(%{"resource" => uri}) when is_binary(uri), do: uri
  defp archival_object_resource_uri(%{"resource" => %{"ref" => uri}}) when is_binary(uri), do: uri

  defp archival_object_resource_uri(%{"ancestors" => ancestors}) when is_list(ancestors) do
    Enum.find_value(ancestors, fn
      uri when is_binary(uri) -> if String.contains?(uri, "/resources/"), do: uri
      %{"ref" => uri} when is_binary(uri) -> if String.contains?(uri, "/resources/"), do: uri
      _ -> nil
    end)
  end

  defp archival_object_resource_uri(_result), do: nil

  defp search_hit(result) do
    %{
      uri: result["uri"],
      title: result["title"],
      identifier: result["identifier"]
    }
  end

  @doc "Deletes a record by its ArchivesSpace URI"
  def delete_record(uri) do
    case delete(uri) do
      {:ok, %{status: 200}} -> :ok
      {:ok, %{status: 404}} -> :ok
      other -> error(other)
    end
  end

  defp do_request(method, path, opts, token) do
    [method: method, url: path, base_url: Config.archives_space_config().url, retry: false]
    |> Keyword.merge(opts)
    |> Req.new()
    |> Req.Request.put_header("x-archivesspace-session", token)
    |> Req.Request.append_request_steps(meadow_user_agent: &Meadow.HTTP.Base.attach_user_agent/1)
    |> Req.request()
  end

  @doc "Returns a cached session token, logging in if necessary"
  def session_token do
    case Cachex.get(Meadow.Cache, @session_cache_key) do
      {:ok, nil} -> login()
      {:ok, token} -> {:ok, token}
    end
  end

  def invalidate_session do
    Cachex.del(Meadow.Cache, @session_cache_key)
    :ok
  end

  defp login do
    with %{url: url, user: user, password: password} <- Config.archives_space_config() do
      Req.post(
        base_url: url,
        url: "/users/:user/login",
        path_params: [user: user],
        form: [password: password],
        retry: false
      )
      |> case do
        {:ok, %{status: 200, body: %{"session" => token}}} ->
          Cachex.put(Meadow.Cache, @session_cache_key, token, expire: @session_ttl)
          {:ok, token}

        {:ok, %{status: status, body: body}} ->
          Logger.error("ArchivesSpace login failed with status #{status}: #{inspect(body)}")
          {:error, "ArchivesSpace login failed with status #{status}"}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  defp error({:ok, %{status: status, body: body}}),
    do: {:error, "ArchivesSpace returned status #{status}: #{inspect(body)}"}

  defp error({:error, error}), do: {:error, error}
end
