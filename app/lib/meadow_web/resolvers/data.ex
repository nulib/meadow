defmodule MeadowWeb.Resolvers.Data do
  @moduledoc """
  Absinthe GraphQL query resolver for Data Context

  """
  alias Meadow.AI.Provenance
  alias Meadow.Data.{FileSets, Works}
  alias Meadow.Data.Works.TransferFileSets
  alias Meadow.Pipeline
  alias Meadow.Utils.AWS.S3, as: S3Utils
  alias Meadow.Utils.ChangesetErrors

  def works(_, args, _) do
    {:ok, Works.list_works(args)}
  end

  def work(_, %{id: id}, _) do
    {:ok, Works.get_work!(id)}
  end

  def work(_, %{accession_number: accession_number}, _) do
    {:ok, Works.get_work_by_accession_number!(accession_number)}
  end

  def create_work(_, args, _) do
    case Works.create_work(args) do
      {:error, changeset} ->
        {:error, message: "Could not create work", details: humanize_work_changeset(changeset)}

      {:error, operation, changeset} ->
        {:error,
         message: "Could not create work",
         details:
           Enum.map(humanize_work_changeset(changeset), fn error ->
             set_error_key(error, operation)
           end)}

      {:ok, work} ->
        {:ok, work}
    end
  end

  defp set_error_key({:value_id, value}, operation), do: %{operation => value}
  defp set_error_key(property, _), do: property

  def update_work(_, %{id: id, work: work_params}, resolution) do
    work = Works.get_work!(id)
    {attestations, work_params} = Map.pop(work_params, :human_authored_attestations, [])

    case Works.update_work(work, work_params) do
      {:error, changeset} ->
        {:error, message: "Could not update work", details: humanize_work_changeset(changeset)}

      {:ok, updated_work} ->
        actor = actor_username(resolution)
        attested_paths = Enum.map(attestations, & &1.field_path)

        # Record any direct human edits of AI-provenanced fields so the origin
        # reflects human mediation instead of silently staying "AI generated".
        # Skip fields the user explicitly attested as human-authored — those go
        # through the attestation path below so they don't also pick up an
        # "AI + human edited" event.
        Provenance.record_work_manual_edit(work, updated_work, actor, except: attested_paths)
        record_attestations(work, updated_work, attestations, actor)
        {:ok, updated_work}
    end
  end

  # Record an explicit human attestation for each field the user marked as
  # human-authored. Reasons may differ per field, so record them one field at a
  # time. Failures are logged inside Provenance and must not fail the save.
  defp record_attestations(_work, _updated_work, [], _actor), do: :ok

  defp record_attestations(work, updated_work, attestations, actor) do
    Enum.each(attestations, fn %{field_path: field_path} = attestation ->
      Provenance.record_work_human_attestation(
        work,
        updated_work,
        [field_path],
        actor,
        reason: Map.get(attestation, :reason)
      )
    end)
  end

  def attest_human_authored_metadata(
        _,
        %{work_id: work_id, field_paths: field_paths} = args,
        resolution
      ) do
    work = Works.get_work!(work_id)

    # Attest-without-edit: the live work is unchanged, so before == after. The
    # attestation event still records both values for an auditable trail.
    case Provenance.record_work_human_attestation(
           work,
           work,
           field_paths,
           actor_username(resolution),
           reason: Map.get(args, :reason)
         ) do
      {:ok, _attested} ->
        {:ok, Works.get_work!(work_id)}

      {:error, reasons} ->
        {:error, message: "Could not attest human-authored metadata", details: inspect(reasons)}
    end
  end

  defp actor_username(%{context: %{current_user: %{username: username}}}), do: username
  defp actor_username(_), do: nil

  def set_work_image(_, %{work_id: work_id, file_set_id: file_set_id}, _) do
    work = Works.get_work!(work_id)
    file_set = FileSets.get_file_set!(file_set_id)

    case Works.set_representative_image(work, file_set) do
      {:error, changeset} ->
        {:error, message: "Could not update work", details: humanize_work_changeset(changeset)}

      {:ok, work} ->
        {:ok, work}
    end
  end

  def delete_work(_, args, _) do
    work = Works.get_work!(args[:work_id])

    case Works.delete_work(work) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not delete work", details: humanize_work_changeset(changeset)
        }

      {:ok, work} ->
        {:ok, work}
    end
  end

  def add_work_to_collection(_, %{work_id: work_id, collection_id: collection_id}, _) do
    work = Works.get_work!(work_id)

    case Works.update_work(work, %{collection_id: collection_id}) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not add work to collection", details: humanize_work_changeset(changeset)
        }

      {:ok, work} ->
        {:ok, work}
    end
  end

  defp humanize_work_changeset(changeset) do
    ChangesetErrors.humanize_errors(changeset,
      flatten: [:administrative_metadata, :descriptive_metadata]
    )
  end

  def file_sets(_, _args, _) do
    {:ok, FileSets.list_file_sets()}
  end

  def file_set(_, %{id: id}, _) do
    {:ok, FileSets.get_file_set!(id)}
  end

  def file_set(_, %{accession_number: accession_number}, _) do
    {:ok, FileSets.get_file_set_by_accession_number!(accession_number)}
  end

  def ingest_file_set(_, args, _) do
    case Pipeline.ingest_file_set(args) do
      {:error, changeset} ->
        {:error,
         message: "Could not create file set", details: ChangesetErrors.humanize_errors(changeset)}

      {:ok, file_set} ->
        {:ok, file_set}
    end
  end

  def delete_file_set(_, args, _) do
    file_set = FileSets.get_file_set!(args[:file_set_id])

    case FileSets.delete_file_set(file_set) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not delete file_set",
          details: ChangesetErrors.humanize_errors(changeset)
        }

      {:ok, file_set} ->
        {:ok, file_set}
    end
  end

  def transcribe_file_set(_, args, resolution) do
    opts =
      []
      |> maybe_add_opt(:language, args[:language])
      |> maybe_add_opt(:model, args[:model])
      |> maybe_add_opt(:context, args[:context])
      |> maybe_add_opt(:actor, actor_username(resolution))

    case FileSets.transcribe_file_set(args[:file_set_id], opts) do
      {:ok, annotation} ->
        {:ok, annotation}

      {:error, :invalid_role} ->
        {:error, message: "Transcription is only available for Access (A) file sets"}

      {:error, :invalid_work_type} ->
        {:error, message: "Transcription is only available for Image works"}

      {:error, reason} ->
        {
          :error,
          message: "Could not transcribe file_set",
          details: transcribe_file_set_error_details(reason)
        }
    end
  end

  defp transcribe_file_set_error_details(%Ecto.Changeset{} = changeset),
    do: ChangesetErrors.humanize_errors(changeset)

  defp transcribe_file_set_error_details({:file_set_not_found, _file_set_id}),
    do: %{"file_set" => "was not found"}

  defp transcribe_file_set_error_details(reason), do: inspect(reason)

  def update_file_set_annotation(_, args, resolution) do
    opts = %{actor: actor_username(resolution)}
    opts = if args[:language], do: Map.put(opts, :language, args[:language]), else: opts

    case FileSets.update_annotation_content(args[:annotation_id], args[:content], opts) do
      {:ok, annotation} ->
        {:ok, annotation}

      {:error, :not_found} ->
        {:error, message: "Annotation not found"}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error,
         message: "Could not update annotation",
         details: ChangesetErrors.humanize_errors(changeset)}

      {:error, reason} ->
        {:error, message: "Could not update annotation", details: inspect(reason)}
    end
  end

  def upsert_file_set_annotation(_, args, _) do
    opts = if args[:language], do: %{language: args[:language]}, else: %{}

    case FileSets.upsert_annotation_content(
           args[:file_set_id],
           args[:type],
           args[:content],
           opts
         ) do
      {:ok, annotation} ->
        {:ok, annotation}

      {:error, :file_set_not_found} ->
        {:error, message: "File set not found"}

      {:error, {:invalid_annotation_content, message}} ->
        {:error, message: "Invalid annotation content", details: message}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error,
         message: "Could not upsert annotation",
         details: ChangesetErrors.humanize_errors(changeset)}

      {:error, reason} ->
        {:error, message: "Could not upsert annotation", details: inspect(reason)}
    end
  end

  def delete_file_set_annotation(_, args, resolution) do
    case FileSets.get_annotation(args[:annotation_id]) do
      nil ->
        {:error, message: "Annotation not found"}

      annotation ->
        case FileSets.delete_annotation(annotation, actor_username(resolution)) do
          {:ok, annotation} ->
            {:ok, annotation}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error,
             message: "Could not delete annotation",
             details: ChangesetErrors.humanize_errors(changeset)}

          {:error, reason} ->
            {:error, message: "Could not delete annotation", details: inspect(reason)}
        end
    end
  end

  defp maybe_add_opt(opts, _key, nil), do: opts
  defp maybe_add_opt(opts, key, value), do: Keyword.put(opts, key, value)

  def list_ingest_bucket_objects(_, %{prefix: prefix}, _) do
    prefix =
      cond do
        Enum.member?(["", "/"], prefix) -> ""
        String.ends_with?(prefix, "/") -> prefix
        true -> prefix <> "/"
      end

    {:ok, S3Utils.list_ingest_bucket_objects(prefix: prefix)}
  end

  def list_ingest_bucket_objects(_, _, _) do
    {:ok, S3Utils.list_ingest_bucket_objects()}
  end

  def replace_file_set(_, %{id: id} = params, _) do
    file_set = FileSets.get_file_set!(id)

    case Pipeline.replace_the_file_set(file_set, Map.delete(params, :id)) do
      {:error, changeset} ->
        {:error,
         message: "Could not replace file set",
         details: ChangesetErrors.humanize_errors(changeset)}

      {:ok, file_set} ->
        {:ok, file_set}
    end
  end

  def update_file_set(_, %{id: id} = params, _) do
    file_set = FileSets.get_file_set!(id)

    case FileSets.update_file_set(file_set, Map.delete(params, :id)) do
      {:error, changeset} ->
        {:error,
         message: "Could not update FileSet", details: ChangesetErrors.humanize_errors(changeset)}

      {:ok, file_set} ->
        {:ok, file_set}
    end
  end

  def update_file_sets(_, file_set_updates, _) do
    case FileSets.update_file_sets(file_set_updates.file_sets) do
      {:error, index, changeset} ->
        {:error,
         message: "Update failed: #{index}", details: ChangesetErrors.humanize_errors(changeset)}

      {:ok, file_sets} ->
        {:ok, file_sets}
    end
  end

  def update_access_file_order(
        _,
        %{work_id: work_id, file_set_ids: file_set_ids},
        _
      ) do
    case Works.update_file_set_order(work_id, "A", file_set_ids) do
      {:error, message} when is_binary(message) ->
        {
          :error,
          message: "Could not update file set order", details: %{error: message}
        }

      {:error, changeset} ->
        {
          :error,
          message: "Could not update file set order",
          details: ChangesetErrors.humanize_errors(changeset)
        }

      {:ok, %{work: work}} ->
        {:ok, work}
    end
  end

  def verify_file_sets(_, %{work_id: work_id}, _) do
    {:ok, Works.verify_file_sets(work_id)}
  end

  def transfer_file_sets(_, %{from_work_id: from_work_id, to_work_id: to_work_id}, _) do
    case TransferFileSets.transfer(from_work_id, to_work_id) do
      {:ok, to_work_id} -> {:ok, to_work_id}
      {:error, reason} -> {:error, reason}
    end
  end

  def transfer_file_sets_subset(_, args, _) do
    case TransferFileSets.transfer_subset(args) do
      {:ok, result} -> {:ok, result}
      {:error, error} -> {:error, message: error}
    end
  end
end
