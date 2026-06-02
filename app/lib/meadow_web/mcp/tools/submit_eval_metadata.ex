defmodule MeadowWeb.MCP.Tools.SubmitEvalMetadata do
  @moduledoc """
  Store the AI-generated metadata for an eval trial.

  Called by the eval agent after analyzing an image and finding subject headings.
  Writes output to the eval_trials table instead of the live Work record, so the
  ground truth is never overwritten.
  """

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "application/json",
    description: "Store AI-generated description and subjects for an eval trial."

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Evals
  require Logger

  @subject_schema %{id: :string, label: :string}

  schema do
    field(:trial_id, :string,
      required: true,
      description: "UUID of the eval trial to record output for"
    )

    field(:description, :string,
      required: true,
      description: "1-3 sentence descriptive summary of the image"
    )

    field(:subjects, {:list, @subject_schema},
      required: true,
      description: "Subject headings from authority_search, each with id (URI) and label"
    )
  end

  @impl true
  def execute(%{trial_id: trial_id, description: description, subjects: subjects}, frame) do
    Logger.info("SubmitEvalMetadata: recording output for trial #{trial_id}")

    output = %{
      description: description,
      subjects: Enum.map(subjects, fn s -> %{id: s.id, label: s.label} end)
    }

    case Evals.record_agent_output(trial_id, output) do
      {:ok, _} ->
        {:reply,
         Response.tool() |> Response.structured(%{recorded: true, trial_id: trial_id}), frame}

      {:error, reason} ->
        {:error, MCPError.execution(inspect(reason)), frame}
    end
  rescue
    error -> {:error, MCPError.protocol(:internal_error, %{error: inspect(error)}), frame}
  end
end
