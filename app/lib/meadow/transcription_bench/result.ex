defmodule Meadow.TranscriptionBench.Result do
  @moduledoc """
  One transcription attempt of a run: a file set sent to a model with a variant, what
  the model returned, and what it cost.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.TranscriptionBench.Run

  @statuses ~w(queued running done error cancelled)
  @outcome_fields ~w(status error started_at duration_ms image_url image_width image_height
                     sent_width sent_height sent_bytes processed_width processed_height stop_reason usage tool_input text
                     reasoning request)a

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "transcription_bench_results" do
    field(:position, :integer, default: 0)
    field(:attempt, :integer, default: 1)
    field(:file_set_id, Ecto.UUID)
    field(:label, :string)
    field(:image_url, :string)
    field(:model, :string)
    field(:variant_id, :string)
    field(:status, :string, default: "queued")
    field(:error, :string)
    field(:started_at, :utc_datetime_usec)
    field(:duration_ms, :integer)
    field(:image_width, :integer)
    field(:image_height, :integer)
    field(:sent_width, :integer)
    field(:sent_height, :integer)
    field(:sent_bytes, :integer)
    field(:processed_width, :integer)
    field(:processed_height, :integer)
    field(:stop_reason, :string)
    field(:usage, :map)
    field(:tool_input, :string)
    field(:text, :string)
    field(:reasoning, :string)
    field(:request, :map)

    # What Meadow.TranscriptionBench.Parser reads out of the model's output, on load.
    field(:parsed, :map, virtual: true)

    belongs_to(:run, Run)

    timestamps()
  end

  def statuses, do: @statuses
  def outcome_fields, do: @outcome_fields

  def changeset(result, attrs) do
    result
    |> cast(attrs, [:run_id, :position, :file_set_id, :label, :image_url, :model, :variant_id])
    |> validate_required([:run_id, :file_set_id, :model, :variant_id])
  end
end
