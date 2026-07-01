defmodule MeadowWeb.MCP.Tools.ApplyWorkMetadata do
  @moduledoc """
  Apply AI-generated metadata (description and subjects) to a work's descriptive metadata.
  Called by the pipeline metadata agent after analyzing an image.
  """

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "application/json",
    description: "Apply AI-generated description and subjects to a work's descriptive metadata."

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.AI.Provenance
  alias Meadow.Config
  alias Meadow.Data.Works
  alias Meadow.Repo
  require Logger

  @subject_schema %{
    id: :string,
    label: :string
  }
  @ai_note_prefix "Some metadata created with the assistance of AI"

  schema do
    field(:work_id, :string,
      required: true,
      description: "UUID of the work to update"
    )

    field(:description, :string,
      required: true,
      description: "1-3 sentence descriptive summary of the image"
    )

    field(:subjects, {:list, @subject_schema},
      required: true,
      description: "Array of subject headings from authority_search, each with id (URI) and label"
    )
  end

  @impl true
  def execute(%{work_id: work_id, description: description, subjects: subjects}, frame) do
    if get_in(frame.assigns, [:context, :eval]) == true or
         get_in(frame.assigns, ["context", "eval"]) == true do
      Logger.error("ApplyWorkMetadata: refusing eval-context call for work #{work_id}")
      {:error, MCPError.execution("apply_work_metadata is disabled during eval runs"), frame}
    else
      do_execute(work_id, description, subjects, frame)
    end
  end

  defp do_execute(work_id, description, subjects, frame) do
    Logger.info("ApplyWorkMetadata: updating work #{work_id}")

    work = Works.get_work!(work_id)

    subject_attrs =
      Enum.map(subjects, fn %{id: id} ->
        %{role: %{id: "TOPICAL", scheme: "subject_role"}, term: %{id: id}}
      end)

    current_date = Date.utc_today() |> Date.to_iso8601()
    note_text = "#{@ai_note_prefix} (#{Config.ai(:model)}) on #{current_date}"

    # Mint the description item's id up front so the applied work item and the
    # provenance target share it — no apply-time value matching needed.
    description_entry = %{id: Ecto.UUID.generate(), value: description}

    result =
      Repo.transaction(fn ->
        updated_work =
          case Works.update_work(work, %{
                 descriptive_metadata: %{
                   description: [description_entry],
                   subject: subject_attrs,
                   notes: [
                     %{
                       note: note_text,
                       type: %{id: "LOCAL_NOTE", scheme: "note_type", label: "Local Note"}
                     }
                   ]
                 }
               }) do
            {:ok, updated_work} -> updated_work
            {:error, changeset} -> Repo.rollback(changeset)
          end

        activity =
          %{
            activity_type: "metadata_direct_apply",
            model: Config.ai(:model),
            ai_use_type: "metadata_generation",
            access_mode: "retrieval_based",
            reversibility: "reversible",
            model_type: "generative_ai",
            input: %{work_id: work_id},
            output: %{description: description, subjects: subjects},
            work_id: work_id,
            status: "completed",
            completed_at: DateTime.utc_now()
          }
          |> Provenance.create_activity()
          |> unwrap_or_rollback()

        Provenance.add_source(activity, Provenance.work_source_attrs(work))
        |> unwrap_or_rollback()

        Provenance.record_targets_for_operations(
          activity,
          "Work",
          work_id,
          %{
            replace: %{
              descriptive_metadata: %{
                description: [description_entry],
                subject: subject_attrs
              }
            }
          },
          origin: "ai_generated",
          status: "applied",
          event_type: "applied",
          target_attrs: %{
            premis_object_category: "intellectual_entity",
            object_identifier_type: "Meadow Work",
            object_identifier_value: work_id,
            c2pa_action: "c2pa.edited",
            digital_source_type_uri:
              "https://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia",
            human_oversight_level: "human_review_required",
            c2pa_assertion_label: "c2pa.ai-disclosure"
          }
        )

        updated_work
      end)

    case result do
      {:ok, _updated_work} ->
        {:reply, Response.tool() |> Response.structured(%{updated: true, work_id: work_id}),
         frame}

      {:error, reason} ->
        {:error, MCPError.execution(inspect(reason)), frame}
    end
  rescue
    error -> {:error, MCPError.protocol(:internal_error, %{error: inspect(error)}), frame}
  end

  defp unwrap_or_rollback({:ok, result}), do: result
  defp unwrap_or_rollback({:error, reason}), do: Repo.rollback(reason)
end
