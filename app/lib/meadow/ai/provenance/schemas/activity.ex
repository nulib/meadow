defmodule Meadow.AI.Provenance.Schemas.Activity do
  @moduledoc "AI provenance activity."

  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.AI.Provenance.Schemas.{Source, Target}

  @statuses ~w(pending completed failed)

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ai_activities" do
    field(:activity_type, :string)
    field(:system_name, :string)
    field(:system_version, :string)
    field(:model, :string)
    field(:prompt_version, :string)
    field(:prompt_text, :string)
    field(:prompt_hash, :string)
    field(:input, :map)
    field(:output, :map)
    field(:output_hash, :string)
    field(:cost_usd, :float)
    field(:started_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)
    field(:initiated_by, :string)
    field(:user_category, :string)
    field(:retention_policy, :string)
    field(:ai_use_type, :string)
    field(:access_mode, :string)
    field(:reversibility, :string)
    field(:model_provider, :string)
    field(:model_version, :string)
    field(:model_type, :string)
    field(:c2pa_manifest_id, :string)
    field(:c2pa_claim_id, :string)
    field(:c2pa_validation_status, :string)
    field(:c2pa_signature_status, :string)
    field(:status, :string, default: "pending")
    field(:error, :string)
    field(:work_id, Ecto.UUID)
    field(:file_set_id, Ecto.UUID)
    field(:plan_id, Ecto.UUID)
    field(:plan_change_id, Ecto.UUID)

    has_many(:sources, Source, foreign_key: :activity_id)
    has_many(:targets, Target, foreign_key: :activity_id)

    timestamps()
  end

  def changeset(activity \\ %__MODULE__{}, attrs) do
    activity
    |> cast(attrs, [
      :activity_type,
      :system_name,
      :system_version,
      :model,
      :prompt_version,
      :prompt_text,
      :prompt_hash,
      :input,
      :output,
      :output_hash,
      :cost_usd,
      :started_at,
      :completed_at,
      :initiated_by,
      :user_category,
      :retention_policy,
      :ai_use_type,
      :access_mode,
      :reversibility,
      :model_provider,
      :model_version,
      :model_type,
      :c2pa_manifest_id,
      :c2pa_claim_id,
      :c2pa_validation_status,
      :c2pa_signature_status,
      :status,
      :error,
      :work_id,
      :file_set_id,
      :plan_id,
      :plan_change_id
    ])
    |> put_hashes()
    |> validate_required([:activity_type, :status])
    |> validate_inclusion(:status, @statuses)
  end

  defp put_hashes(changeset) do
    changeset
    |> maybe_put_hash(:prompt_text, :prompt_hash)
    |> maybe_put_hash(:output, :output_hash)
  end

  defp maybe_put_hash(changeset, source, target) do
    if get_field(changeset, target) do
      changeset
    else
      case get_field(changeset, source) do
        nil -> changeset
        value -> put_change(changeset, target, hash(value))
      end
    end
  end

  defp hash(value) when is_binary(value),
    do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)

  defp hash(value), do: value |> Jason.encode!() |> hash()
end
