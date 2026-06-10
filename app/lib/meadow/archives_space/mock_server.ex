defmodule Meadow.ArchivesSpace.MockServer do
  @moduledoc """
  Mock ArchivesSpace API server for testing Meadow.ArchivesSpace

  Emulates the slice of the ArchivesSpace staff API Meadow uses:

  * Session auth: `POST /users/:user/login` issues a session token; all
    other routes require a valid `X-ArchivesSpace-Session` header and
    return 412 without one (sessions can be force-expired with
    `expire_sessions/0`)
  * Archival objects, resources, and digital objects: GET/POST/DELETE by
    URI, with optimistic locking on `lock_version` (409 on mismatch)
  * Digital objects deduplicated on `digital_object_id` and subjects on
    `authority_id`, returning 400 with a `conflicting_record` error like
    real ArchivesSpace
  * Deleting a digital object removes instances referencing it from
    archival objects, as ArchivesSpace does

  Backed by a Cachex store, so all records are cleared every time the
  server is stopped (or explicitly with `reset/0`).
  """

  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    json_decoder: JSON
  )

  plug(:authenticate)
  plug(:dispatch)

  @cache Meadow.ArchivesSpace.MockServer.Cache
  @password "admin"

  # Small waypoint size so tests exercise waypoint pagination
  @waypoint_size 2

  # Test setup API

  @doc "Clears all records and sessions"
  def reset, do: Cachex.clear!(@cache)

  @doc "Invalidates all issued session tokens (forces 412 on the next request)"
  def expire_sessions, do: Cachex.put!(@cache, :sessions, MapSet.new())

  @doc "Stores a record directly, returning it with its uri and lock_version set"
  def seed(%{"uri" => uri} = record) do
    record = Map.put_new(record, "lock_version", 0)
    Cachex.put!(@cache, {:record, uri}, record)
    Cachex.put!(@cache, :record_uris, MapSet.put(record_uris(), uri))
    record
  end

  @doc "Creates a resource (finding aid) record in the given repository"
  def create_resource(repo_id, attrs \\ %{}) do
    id = next_id()

    %{
      "jsonmodel_type" => "resource",
      "uri" => "/repositories/#{repo_id}/resources/#{id}",
      "title" => "Resource #{id}",
      "level" => "collection",
      "ead_location" => "https://findingaids.example.edu/#{id}",
      "notes" => []
    }
    |> Map.merge(attrs)
    |> seed()
  end

  @doc "Creates an archival object record in the given repository"
  def create_archival_object(repo_id, attrs \\ %{}) do
    id = next_id()

    %{
      "jsonmodel_type" => "archival_object",
      "uri" => "/repositories/#{repo_id}/archival_objects/#{id}",
      "ref_id" => "ref#{id}",
      "title" => "Archival Object #{id}",
      "level" => "file",
      "notes" => [],
      "subjects" => [],
      "instances" => []
    }
    |> Map.merge(attrs)
    |> seed()
  end

  @doc "Creates a digital object record in the given repository"
  def create_digital_object(repo_id, attrs \\ %{}) do
    id = next_id()

    %{
      "jsonmodel_type" => "digital_object",
      "uri" => "/repositories/#{repo_id}/digital_objects/#{id}",
      "digital_object_id" => "do#{id}",
      "title" => "Digital Object #{id}",
      "file_versions" => []
    }
    |> Map.merge(attrs)
    |> seed()
  end

  @doc "Builds a digital object instance referencing the given digital object"
  def digital_object_instance(%{"uri" => uri}),
    do: %{"instance_type" => "digital_object", "digital_object" => %{"ref" => uri}}

  @doc "Fetches a stored record by URI"
  def get_record(uri), do: Cachex.get!(@cache, {:record, uri})

  @doc "Lists the digital object component records under a digital object, in position order"
  def list_digital_object_components(digital_object_uri), do: do_children_of(digital_object_uri)

  # Routes

  post "/users/:user/login" do
    if Map.get(conn.params, "password") == @password do
      token = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      Cachex.put!(@cache, :sessions, MapSet.put(sessions(), token))
      json(conn, 200, %{"session" => token, "user" => %{"username" => user}})
    else
      json(conn, 403, %{"error" => "Login failed"})
    end
  end

  post "/subjects" do
    subject = conn.body_params

    case find_record(fn record ->
           record["jsonmodel_type"] == "subject" &&
             record["authority_id"] == subject["authority_id"]
         end) do
      nil ->
        uri = "/subjects/#{next_id()}"
        seed(subject |> Map.put("uri", uri))
        json(conn, 200, %{"status" => "Created", "uri" => uri})

      existing ->
        json(conn, 400, %{"error" => %{"conflicting_record" => [existing["uri"]]}})
    end
  end

  post "/repositories/:repo_id/digital_objects" do
    digital_object = conn.body_params

    case find_record(fn record ->
           record["jsonmodel_type"] == "digital_object" &&
             record["digital_object_id"] == digital_object["digital_object_id"]
         end) do
      nil ->
        uri = "/repositories/#{repo_id}/digital_objects/#{next_id()}"
        seed(digital_object |> Map.put("uri", uri))
        json(conn, 200, %{"status" => "Created", "uri" => uri})

      existing ->
        json(conn, 400, %{"error" => %{"conflicting_record" => [existing["uri"]]}})
    end
  end

  post "/repositories/:repo_id/digital_object_components" do
    uri = "/repositories/#{repo_id}/digital_object_components/#{next_id()}"
    seed(conn.body_params |> Map.put("uri", uri))
    json(conn, 200, %{"status" => "Created", "uri" => uri})
  end

  post "/agents/people" do
    create_agent(conn, "/agents/people")
  end

  post "/agents/corporate_entities" do
    create_agent(conn, "/agents/corporate_entities")
  end

  get "/search" do
    query = conn.params |> Map.get("q", "") |> String.downcase()
    types = Map.get(conn.params, "type", [])

    results =
      records()
      |> Enum.filter(fn record ->
        (types == [] or record["jsonmodel_type"] in types) and
          record
          |> searchable_text()
          |> String.contains?(query)
      end)
      |> Enum.sort_by(&record_position/1)
      |> Enum.map(
        &%{
          "uri" => &1["uri"],
          "title" => &1["title"],
          "identifier" => &1["identifier"],
          "resource" => resource_ref(&1),
          "primary_type" => &1["jsonmodel_type"]
        }
      )

    json(conn, 200, %{
      "results" => results,
      "this_page" => 1,
      "last_page" => 1,
      "total_hits" => length(results)
    })
  end

  get "/repositories/:repo_id/resources/:id/tree/root" do
    uri = "/repositories/#{repo_id}/resources/#{id}"

    case get_record(uri) do
      nil ->
        json(conn, 404, %{"error" => "Record not found"})

      resource ->
        json(conn, 200, tree_node(resource, children_of(uri, nil)))
    end
  end

  get "/repositories/:repo_id/digital_objects/:id/tree/root" do
    uri = "/repositories/#{repo_id}/digital_objects/#{id}"

    case get_record(uri) do
      nil ->
        json(conn, 404, %{"error" => "Record not found"})

      digital_object ->
        json(conn, 200, tree_node(digital_object, do_children_of(uri)))
    end
  end

  get "/repositories/:repo_id/digital_objects/:id/tree/waypoint" do
    uri = "/repositories/#{repo_id}/digital_objects/#{id}"
    offset = conn.params |> Map.get("offset", "0") |> String.to_integer()

    nodes =
      uri
      |> do_children_of()
      |> Enum.drop(offset * @waypoint_size)
      |> Enum.take(@waypoint_size)
      |> Enum.map(&tree_node(&1, []))

    json(conn, 200, nodes)
  end

  get "/repositories/:repo_id/resources/:id/tree/waypoint" do
    uri = "/repositories/#{repo_id}/resources/#{id}"
    parent_uri = Map.get(conn.params, "parent_node")
    offset = conn.params |> Map.get("offset", "0") |> String.to_integer()

    nodes =
      children_of(uri, parent_uri)
      |> Enum.drop(offset * @waypoint_size)
      |> Enum.take(@waypoint_size)
      |> Enum.map(&tree_node(&1, children_of(uri, &1["uri"])))

    json(conn, 200, nodes)
  end

  get "/repositories/:repo_id/:record_type/:id" do
    case get_record(current_uri(conn)) do
      nil -> json(conn, 404, %{"error" => "Record not found"})
      record -> json(conn, 200, record)
    end
  end

  post "/repositories/:repo_id/:record_type/:id" do
    update_record(conn, current_uri(conn))
  end

  get "/subjects/:id" do
    case get_record(current_uri(conn)) do
      nil -> json(conn, 404, %{"error" => "Record not found"})
      record -> json(conn, 200, record)
    end
  end

  get "/agents/:agent_type/:id" do
    case get_record(current_uri(conn)) do
      nil -> json(conn, 404, %{"error" => "Record not found"})
      record -> json(conn, 200, record)
    end
  end

  delete "/repositories/:repo_id/:record_type/:id" do
    uri = current_uri(conn)

    case get_record(uri) do
      nil ->
        json(conn, 404, %{"error" => "Record not found"})

      record ->
        Cachex.del!(@cache, {:record, uri})
        Cachex.put!(@cache, :record_uris, MapSet.delete(record_uris(), uri))

        if record["jsonmodel_type"] == "digital_object" do
          remove_instances_of(uri)
          delete_components_of(uri)
        end

        json(conn, 200, %{"status" => "Deleted", "id" => id})
    end
  end

  match _ do
    json(conn, 404, %{"error" => "Record not found"})
  end

  # Implementation

  defp update_record(conn, uri) do
    incoming = conn.body_params

    case get_record(uri) do
      nil ->
        json(conn, 404, %{"error" => "Record not found"})

      %{"lock_version" => lock_version} ->
        if lock_version == incoming["lock_version"] do
          record = incoming |> Map.merge(%{"uri" => uri, "lock_version" => lock_version + 1})
          Cachex.put!(@cache, {:record, uri}, record)

          json(conn, 200, %{
            "status" => "Updated",
            "uri" => uri,
            "lock_version" => record["lock_version"]
          })
        else
          json(conn, 409, %{
            "error" => %{
              "lock_version" => [
                "The record you tried to update has been modified since you fetched it"
              ]
            }
          })
        end
    end
  end

  defp create_agent(conn, base_path) do
    agent = conn.body_params
    authority_id = agent |> Map.get("names", []) |> List.first(%{}) |> Map.get("authority_id")

    existing =
      authority_id &&
        find_record(fn record ->
          record["jsonmodel_type"] in ["agent_person", "agent_corporate_entity"] &&
            record
            |> Map.get("names", [])
            |> Enum.any?(&(&1["authority_id"] == authority_id))
        end)

    case existing do
      nil ->
        uri = "#{base_path}/#{next_id()}"
        seed(agent |> Map.put("uri", uri))
        json(conn, 200, %{"status" => "Created", "uri" => uri})

      record ->
        json(conn, 400, %{"error" => %{"conflicting_record" => [record["uri"]]}})
    end
  end

  defp do_children_of(digital_object_uri) do
    records()
    |> Enum.filter(fn record ->
      record["jsonmodel_type"] == "digital_object_component" and
        get_in(record, ["digital_object", "ref"]) == digital_object_uri
    end)
    |> Enum.sort_by(&(&1["position"] || 0))
  end

  defp delete_components_of(digital_object_uri) do
    each_record(fn
      %{"jsonmodel_type" => "digital_object_component", "uri" => uri} = record ->
        if get_in(record, ["digital_object", "ref"]) == digital_object_uri do
          Cachex.del!(@cache, {:record, uri})
          Cachex.put!(@cache, :record_uris, MapSet.delete(record_uris(), uri))
        end

      _ ->
        :noop
    end)
  end

  defp remove_instances_of(digital_object_uri) do
    each_record(fn
      %{"jsonmodel_type" => "archival_object", "uri" => uri, "instances" => instances} = record
      when is_list(instances) ->
        kept =
          Enum.reject(instances, &(get_in(&1, ["digital_object", "ref"]) == digital_object_uri))

        if kept != instances do
          Cachex.put!(@cache, {:record, uri}, Map.put(record, "instances", kept))
        end

      _ ->
        :noop
    end)
  end

  defp authenticate(%{path_info: ["users", _, "login"]} = conn, _opts), do: conn

  defp authenticate(conn, _opts) do
    with [token | _] <- get_req_header(conn, "x-archivesspace-session"),
         true <- MapSet.member?(sessions(), token) do
      conn
    else
      _ ->
        conn
        |> json(412, %{"code" => "SESSION_GONE", "error" => "Session is gone"})
        |> halt()
    end
  end

  defp sessions, do: Cachex.get!(@cache, :sessions) || MapSet.new()

  defp find_record(predicate) do
    records()
    |> Enum.find(predicate)
  end

  defp each_record(fun) do
    records()
    |> Enum.each(fun)
  end

  defp records do
    record_uris()
    |> Enum.map(&get_record/1)
    |> Enum.reject(&is_nil/1)
  end

  defp searchable_text(record) do
    [record["title"], record["display_string"]]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> String.downcase()
  end

  defp resource_ref(%{"jsonmodel_type" => "archival_object"} = record),
    do: get_in(record, ["resource", "ref"])

  defp resource_ref(_record), do: nil

  defp record_uris, do: Cachex.get!(@cache, :record_uris) || MapSet.new()

  defp tree_node(record, children) do
    child_count = length(children)

    %{
      "uri" => record["uri"],
      "title" => record["title"] || record["display_string"],
      "jsonmodel_type" => record["jsonmodel_type"],
      "child_count" => child_count,
      "waypoints" => ceil(child_count / @waypoint_size),
      "waypoint_size" => @waypoint_size
    }
  end

  defp children_of(resource_uri, parent_uri) do
    records()
    |> Enum.filter(fn record ->
      record["jsonmodel_type"] == "archival_object" and
        get_in(record, ["resource", "ref"]) == resource_uri and
        get_in(record, ["parent", "ref"]) == parent_uri
    end)
    |> Enum.sort_by(&record_position/1)
  end

  defp record_position(record) do
    record["uri"] |> String.split("/") |> List.last() |> String.to_integer()
  end

  defp current_uri(conn), do: "/" <> Enum.join(conn.path_info, "/")

  defp next_id, do: Cachex.incr!(@cache, :counter)

  defp json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, JSON.encode!(body))
  end
end
