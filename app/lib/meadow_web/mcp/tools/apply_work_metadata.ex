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
  alias Meadow.Config
  alias Meadow.Data.Works
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
    Logger.info("ApplyWorkMetadata: updating work #{work_id}")

    work = Works.get_work!(work_id)

    subject_attrs =
      Enum.map(subjects, fn %{id: id} ->
        %{role: %{id: "TOPICAL", scheme: "subject_role"}, term: %{id: id}}
      end)

    model = Config.ai(:model)
    current_date = Date.utc_today() |> Date.to_iso8601()
    note_text = "#{@ai_note_prefix} (#{model}) on #{current_date}"

    case Works.update_work(work, %{
           descriptive_metadata: %{
             description: [description],
             subject: subject_attrs,
             notes: [
               %{
                 note: note_text,
                 type: %{id: "LOCAL_NOTE", scheme: "note_type", label: "Local Note"}
               }
             ]
           }
         }) do
      {:ok, _updated_work} ->
        {:reply, Response.tool() |> Response.structured(%{updated: true, work_id: work_id}),
         frame}

      {:error, changeset} ->
        {:error, MCPError.execution(inspect(changeset)), frame}
    end
  rescue
    error -> {:error, MCPError.protocol(:internal_error, %{error: inspect(error)}), frame}
  end
end
