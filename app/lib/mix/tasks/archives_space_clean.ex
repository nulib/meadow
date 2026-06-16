defmodule Mix.Tasks.Meadow.ArchivesSpace.Clean do
  @moduledoc """
  Removes the fixture data created by `mix meadow.archives_space.seed` from an
  ArchivesSpace instance, leaving the instance (and its docker stack) running.

  Only ever touches the fictional fixture repositories the seed task creates:
  every seeded repository carries a `repo_code` starting with `meadow_fixture_`,
  and this task deletes only those. By default each fixture repository is
  deleted outright, which ArchivesSpace cascades to every record inside it
  (resources, archival objects, digital objects), returning the instance to its
  pre-seed state. Repository deletion runs as an ArchivesSpace background job, so
  it may finish a moment after this task returns.

  With `--keep-repositories` there is no repository to cascade through, so the
  resources and digital objects are removed via the `POST /batch_delete` bulk
  endpoint instead, leaving the empty repositories behind.

  Real repositories and any other data are never affected.

  ## Usage

      mix meadow.archives_space.clean [options]

  ## Options

    * `--url` - ArchivesSpace backend API URL (default: the `ARCHIVESSPACE_URL`
      environment variable, or `http://localhost:8089`).
    * `--user` - ArchivesSpace user (default: `admin`)
    * `--password` - ArchivesSpace password (default: `admin`)
    * `--keep-repositories` - delete the resources and digital objects but leave
      the (now empty) fixture repositories in place, so a subsequent seed reuses
      them.

  ## Examples

      mix meadow.archives_space.clean
      mix meadow.archives_space.clean --keep-repositories
  """
  use Mix.Task

  alias Meadow.ArchivesSpace.Client

  @shortdoc "Remove seeded fixture data from a (dev) ArchivesSpace"

  @switches [
    url: :string,
    user: :string,
    password: :string,
    keep_repositories: :boolean
  ]

  @default_url "http://localhost:8089"
  @default_user "admin"
  @default_password "admin"

  # Repositories created by `mix meadow.archives_space.seed` all carry a
  # repo_code with this prefix, so cleaning only ever touches fixture data.
  @fixture_prefix "meadow_fixture_"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case OptionParser.parse(args, strict: @switches) do
      {opts, [], []} ->
        clean(opts)

      {_, _, invalid} when invalid != [] ->
        Mix.raise("Invalid options: #{inspect(invalid)}")

      {_, extra, _} ->
        Mix.raise("Unexpected arguments: #{inspect(extra)} (this task takes options only)")
    end
  end

  defp clean(opts) do
    configure_client(opts)

    case fixture_repositories() do
      [] ->
        Mix.shell().info(
          "No fixture repositories (repo_code starting with \"#{@fixture_prefix}\") found; nothing to clean."
        )

      repos ->
        cleaned = Enum.map(repos, &clean_repository(&1, opts))
        report(cleaned, opts)
    end
  end

  # Point the ArchivesSpace client at the requested instance for this run.
  defp configure_client(opts) do
    url = opts[:url] || System.get_env("ARCHIVESSPACE_URL", @default_url)

    Application.put_env(:meadow, :archives_space, %{
      url: url,
      user: opts[:user] || @default_user,
      password: opts[:password] || @default_password
    })

    Client.invalidate_session()

    case Client.session_token() do
      {:ok, _token} ->
        :ok

      {:error, reason} ->
        Mix.raise("""
        Could not authenticate to ArchivesSpace at #{url}: #{inspect(reason)}
        Is the instance running? Start the docker stack with:
          make -C infrastructure/archivesspace wait
        """)
    end
  end

  defp fixture_repositories do
    case Client.get("/repositories") do
      {:ok, %{status: 200, body: repos}} when is_list(repos) ->
        Enum.filter(repos, fn repo ->
          is_binary(repo["repo_code"]) and String.starts_with?(repo["repo_code"], @fixture_prefix)
        end)

      other ->
        Mix.raise("Could not list ArchivesSpace repositories: #{inspect(other)}")
    end
  end

  defp clean_repository(%{"uri" => repo_uri} = repo, opts) do
    if opts[:keep_repositories] do
      # No repository to cascade through, so clear its contents. Deleting a
      # resource cascades to its archival objects; digital objects are
      # independent records, so collect both sets of URIs and bulk-delete them.
      resource_uris = record_uris(repo_uri, "resources")
      digital_object_uris = record_uris(repo_uri, "digital_objects")
      batch_delete(resource_uris ++ digital_object_uris)

      %{
        repo_code: repo["repo_code"],
        uri: repo_uri,
        resources: length(resource_uris),
        digital_objects: length(digital_object_uris),
        repository_deleted: false
      }
    else
      # Deleting the repository cascades to every record it contains.
      case Client.delete_record(repo_uri) do
        :ok -> :ok
        other -> Mix.raise("Could not delete repository #{repo_uri}: #{inspect(other)}")
      end

      %{repo_code: repo["repo_code"], uri: repo_uri, repository_deleted: true}
    end
  end

  # Lists the URIs of every record of the given type in the repository.
  # ArchivesSpace's `all_ids=true` returns the bare integer ids.
  defp record_uris(repo_uri, record_type) do
    case Client.get("#{repo_uri}/#{record_type}", params: [all_ids: true]) do
      {:ok, %{status: 200, body: ids}} when is_list(ids) ->
        Enum.map(ids, &"#{repo_uri}/#{record_type}/#{&1}")

      other ->
        Mix.raise("Could not list #{record_type} in #{repo_uri}: #{inspect(other)}")
    end
  end

  # Deletes a list of records in a single request via POST /batch_delete.
  defp batch_delete([]), do: :ok

  defp batch_delete(uris) do
    case Client.post("/batch_delete", json: %{"record_uris" => uris}) do
      {:ok, %{status: 200}} -> :ok
      other -> Mix.raise("Bulk delete failed: #{inspect(other)}")
    end
  end

  defp report(cleaned, opts) do
    summaries =
      cleaned
      |> Enum.map(fn
        %{repository_deleted: true} = entry ->
          "  #{entry.uri} [#{entry.repo_code}]: repository deleted (cascades to all contained records)"

        entry ->
          "  #{entry.uri} [#{entry.repo_code}]: " <>
            "#{entry.resources} resources, #{entry.digital_objects} digital objects deleted (repository kept)"
      end)
      |> Enum.join("\n")

    note =
      if opts[:keep_repositories],
        do: "\nEmpty fixture repositories were kept; re-running the seed will reuse them.",
        else: ""

    Mix.shell().info("""

    Cleaned ArchivesSpace fixture data:

    #{summaries}
    #{note}
    """)
  end
end
