defmodule Meadow.Migration do
  @moduledoc """
  Module to assist with migration of works and file sets from outside Meadow
  """

  alias Ecto.Changeset
  alias Meadow.Config
  alias Meadow.Data.{ControlledTerms, DonutWorks, Works}
  alias Meadow.Data.Schemas.{DonutWork, Work}
  alias Meadow.Pipeline
  alias Meadow.Repo
  alias Meadow.Utils.ChangesetErrors

  import Ecto.Query

  require Logger

  @doc """
  Create pending donut_works records for all manifests in a bucket
  """
  def import(since \\ nil) do
    with bucket <- Config.migration_manifest_bucket() do
      ExAws.S3.list_objects_v2(bucket)
      |> ExAws.stream!()
      |> Stream.filter(fn %{key: key, last_modified: last_modified} ->
        with {:ok, timestamp, _} <- DateTime.from_iso8601(last_modified) do
          String.ends_with?(key, ".json") and (is_nil(since) or since <= timestamp)
        end
      end)
      |> Stream.each(&initialize_manifest/1)
      |> Stream.run()
    end
  end

  @doc """
  Cache authorities for all pending works
  """
  def cache_authorities do
    {:ok, terms} =
      Repo.transaction(
        fn ->
          from(dw in DonutWork, where: dw.status == "pending")
          |> Repo.stream()
          |> Stream.map(fn %{manifest: source} -> source end)
          |> Stream.map(&Meadow.Migration.read_manifest/1)
          |> ControlledTerms.extract_unique_terms()
        end,
        timeout: :infinity
      )

    Logger.info("Pre-caching #{length(terms)} unique terms")

    terms
    |> Enum.reject(&is_nil/1)
    |> Enum.each(&ControlledTerms.fetch/1)
  end

  @doc """
  Migrate all pending donut_works
  """
  def migrate(count) do
    Stream.resource(
      fn -> {count, []} end,
      fn
        {0, results} ->
          {:halt, results}

        {:all, results} ->
          case migrate_one() do
            :noop -> {:halt, results}
            {:ok, donut_work} -> {[donut_work], {:all, [donut_work | results]}}
          end

        {remaining, results} ->
          case migrate_one() do
            :noop -> {:halt, results}
            {:ok, donut_work} -> {[donut_work], {remaining - 1, [donut_work | results]}}
          end
      end,
      fn
        {_count, results} -> Enum.reverse(results)
        results -> Enum.reverse(results)
      end
    )
    |> Enum.to_list()
  end

  @doc """
  Migrate the next pending donut_work
  """
  def migrate_one do
    case DonutWorks.with_next_donut_work(fn
           nil -> :noop
           donut_work -> import_work(donut_work)
         end) do
      {:ok, donut_work} ->
        donut_work |> send_to_pipeline()

      {:error, {donut_work, message}} ->
        donut_work |> DonutWorks.update_donut_work(%{status: "error", error: message})
    end
  end

  @doc """
  Read a work manifest from a JSON source file
  """
  def read_manifest(source) do
    source
    |> Meadow.Utils.Stream.stream_from()
    |> Enum.into("")
    |> Jason.decode!(keys: :atoms)
  end

  defp initialize_manifest(s3) do
    source = "s3://#{Config.migration_manifest_bucket()}/#{s3.key}"
    {:ok, source_time, _} = DateTime.from_iso8601(s3.last_modified)
    source_time = DateTime.truncate(source_time, :second)
    id = Path.basename(source, ".json")

    case migration_records(id) do
      # Work already exists
      %{work: %{exists?: true}} ->
        Logger.warn("Skipping manifest #{source} because work already exists")
        {:ok, :work_exists}

      # Neither Work nor DonutWork exists
      nil ->
        Logger.info("Initializing manifest #{source}")

        DonutWorks.create_donut_work!(%{manifest: source, work_id: id, last_modified: source_time})

      # DonutWork errored but s3 copy is newer than last time
      %{donut_work: %{status: "error", last_modified: record_time}} when record_time < source_time ->
        Logger.info("Reinitializing #{source} with newer manifest")

        DonutWorks.get_donut_work!(id)
        |> DonutWorks.update_donut_work!(%{status: "pending", last_modified: source_time})

      # Manifest already initialized
      %{donut_work: %{exists?: true}} ->
        Logger.warn("Skipping manifest #{source} because it is already initialized")
        {:ok, :donut_work_exists}
    end
  end

  @doc """
  Create a Work changeset from a migration manifest
  """
  def changeset(manifest) do
    manifest
    |> Work.migration_changeset()
  end

  @doc """
  Alter file set manifest's source location and digests to match S3
  """
  def update_file_set_core_metadata(manifest) do
    with {_, result} <-
           manifest
           |> Map.get_and_update(:file_sets, fn
             nil -> {nil, nil}
             file_sets -> {file_sets, Enum.map(file_sets, &update_file_set/1)}
           end) do
      result
    end
  end

  defp set_representative_file_set(work, file_set_id) do
    case file_set_id do
      nil ->
        Logger.info("Setting default representative image for work #{work.id}")
        Works.set_default_representative_image!(work)

      file_set_id ->
        Logger.info("Setting #{file_set_id} as the representative image for work #{work.id}")
        Works.set_representative_image!(work, file_set_id)
    end
  end

  defp extract_representative_file_set_id(manifest) do
    {Map.delete(manifest, :representative_file_set_id),
     Map.get(manifest, :representative_file_set_id)}
  end

  defp import_work(%{manifest: source, work_id: work_id} = donut_work) do
    Logger.info("Importing work #{work_id} from #{source}")

    with {work_attributes, representative_file_set_id} <-
           source
           |> read_manifest()
           |> update_file_set_core_metadata()
           |> extract_representative_file_set_id() do
      case work_attributes |> check_binaries() |> create_work() do
        {:ok, work} ->
          work
          |> set_representative_file_set(representative_file_set_id)

          Logger.info("Marking work #{work_id} complete")
          donut_work |> DonutWorks.update_donut_work(%{status: "complete"})

        {:error, error} ->
          Repo.rollback(error(donut_work, error))
      end
    end
  end

  defp check_binaries(work_attributes) do
    case work_attributes
         |> Map.get(:file_sets, [])
         |> Enum.map(&get_in(&1, [:core_metadata, :location]))
         |> Enum.reject(&Meadow.Utils.Stream.exists?/1) do
      [] -> {:ok, work_attributes}
      missing_binaries -> {:error, "Binaries missing: " <> inspect(missing_binaries)}
    end
  end

  defp create_work({:ok, work_attributes}), do: work_attributes |> changeset() |> Repo.insert()
  defp create_work(passthrough), do: passthrough

  defp error(donut_work, %Changeset{} = changeset) do
    errors =
      ChangesetErrors.humanize_errors(changeset,
        flatten: [:administrative_metadata, :descriptive_metadata]
      )
      |> Enum.map(fn {field, error} -> [field, error] |> Enum.join(" ") end)
      |> Enum.join("; ")

    error(donut_work, errors)
  end

  defp error(%{work_id: work_id} = donut_work, message) do
    Logger.error("Error importing work #{work_id}: #{message}")
    {donut_work, message}
  end

  defp send_to_pipeline({:ok, %DonutWork{work_id: work_id} = donut_work}) do
    case Works.get_work(work_id) |> Repo.preload(:file_sets) do
      nil ->
        {:ok, donut_work}

      work ->
        work |> send_to_pipeline()
        {:ok, donut_work}
    end
  end

  defp send_to_pipeline(%{file_sets: []}), do: :noop

  defp send_to_pipeline(%{file_sets: file_sets, id: work_id}) do
    Logger.info("Work #{work_id}: Sending #{length(file_sets)} file sets to the ingest pipeline")

    file_sets
    |> Enum.each(fn file_set ->
      Pipeline.kickoff(file_set, %{overwrite: "false", role: file_set.role.id})
    end)
  end

  defp send_to_pipeline(other), do: other

  defp update_file_set(file_set) do
    file_set
    |> move_core_metadata()
    |> update_location()
    |> update_digests()
    |> update_original_filename()
    |> update_label()
    |> update_role()
  end

  defp move_core_metadata(%{metadata: metadata} = file_set) do
    file_set
    |> Map.put(:core_metadata, metadata)
    |> Map.delete(:metadata)
  end

  defp move_core_metadata(file_set), do: file_set

  defp update_location(%{core_metadata: %{location: location}} = file_set) do
    result =
      with %{path: key} <- URI.parse(location) do
        %URI{
          scheme: "s3",
          host: Config.migration_binary_bucket(),
          path: key
        }
        |> URI.to_string()
      end

    put_in(file_set, [:core_metadata, :location], result)
  end

  defp update_digests(%{core_metadata: %{location: location}} = file_set) do
    digests =
      with %{host: bucket, path: "/" <> key} <- URI.parse(location) do
        case ExAws.S3.head_object(bucket, key) |> ExAws.request() do
          {:ok, %{status_code: 200, headers: headers}} ->
            headers
            |> Enum.map(fn
              {"x-amz-meta-sha1", value} -> {:sha1, value}
              {"x-amz-meta-sha256", value} -> {:sha256, value}
              _ -> nil
            end)
            |> Enum.reject(&is_nil/1)
            |> Enum.into(%{})

          _ ->
            nil
        end
      end

    put_in(file_set, [:core_metadata, :digests], digests)
  end

  defp update_label(%{core_metadata: %{original_filename: original_filename}} = file_set) do
    case file_set |> get_in([:core_metadata, :label]) do
      nil -> put_in(file_set, [:core_metadata, :label], original_filename)
      "" -> put_in(file_set, [:core_metadata, :label], original_filename)
      _ -> file_set
    end
  end

  defp update_role(%{role: _role} = file_set) do
    put_in(file_set.role, %{id: "A", scheme: "FILE_SET_ROLE"})
  end

  defp update_original_filename(
         %{core_metadata: %{original_filename: original_filename}} = file_set
       ) do
    with %{path: filename} <- URI.parse(original_filename) do
      put_in(file_set, [:core_metadata, :original_filename], filename)
    end
  end

  defp update_original_filename(file_set),
    do: put_in(file_set, [:core_metadata, :original_filename], "")

  # Join DonutWork to Work and return status information on
  # both in a single query
  def migration_records(id) do
    from(dw in DonutWork,
      full_join: w in Work,
      on: w.id == dw.work_id,
      where: dw.work_id == ^id or w.id == ^id,
      select: %{
        donut_work: %{
          exists?: not is_nil(dw.work_id),
          status: dw.status,
          last_modified: dw.last_modified
        },
        work: %{exists?: not is_nil(w.id), id: w.id}
      }
    )
    |> Repo.one()
  end
end
