defmodule MeadowWeb.Resolvers.Data do
  @moduledoc """
  Absinthe GraphQL query resolver for Data Context

  """
  alias Meadow.Pipeline
  alias Meadow.Data.{FileSets, Works}
  alias Meadow.Data.Works.TransferFileSets
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

  def update_work(_, %{id: id, work: work_params}, _) do
    work = Works.get_work!(id)

    case Works.update_work(work, work_params) do
      {:error, changeset} ->
        {:error, message: "Could not update work", details: humanize_work_changeset(changeset)}

      {:ok, work} ->
        {:ok, work}
    end
  end

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

  def transcribe_file_set(_, args, _) do
    opts =
      []
      |> maybe_add_opt(:language, args[:language])
      |> maybe_add_opt(:model, args[:model])

    case FileSets.transcribe_file_set(args[:file_set_id], opts) do
      {:ok, annotation} ->
        {:ok, annotation}

      {:error, :invalid_role} ->
        {:error, message: "Transcription is only available for Access (A) file sets"}

      {:error, :invalid_work_type} ->
        {:error, message: "Transcription is only available for Image works"}

      {:error, reason} ->
        {:error, message: "Could not transcribe file_set", details: inspect(reason)}
    end
  end

  def update_file_set_annotation(_, args, _) do
    opts = if args[:language], do: %{language: args[:language]}, else: %{}

    case FileSets.update_annotation_content(args[:annotation_id], args[:content], opts) do
      {:ok, annotation} ->
        {:ok, annotation}

      {:error, :not_found} ->
        {:error, message: "Annotation not found"}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, message: "Could not update annotation", details: ChangesetErrors.humanize_errors(changeset)}

      {:error, reason} ->
        {:error, message: "Could not update annotation", details: inspect(reason)}
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
