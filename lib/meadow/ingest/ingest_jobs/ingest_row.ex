defmodule Meadow.Ingest.IngestJobs.IngestRow do
  @moduledoc """
  IngestRow represents a single row of an inventory sheet
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type Ecto.ULID

  schema "ingest_rows" do
    belongs_to :ingest_job, Meadow.Ingest.IngestJobs.IngestJob, primary_key: true
    field :row, :integer, primary_key: true
    field :state, :string, default: "pending"

    embeds_many :errors, Error, primary_key: false, on_replace: :delete do
      field :field, :string
      field :message, :string
    end

    embeds_many :fields, Field, primary_key: false, on_replace: :delete do
      field :header, :string
      field :value, :string
    end

    timestamps()
  end

  @doc false
  def changeset(ingest_row, attrs) do
    ingest_row
    |> cast(attrs, [:state])
    |> cast_embed(:errors, with: &error_changeset/2)
    |> cast_embed(:fields, with: &field_changeset/2)
    |> validate_required([:ingest_job_id, :row])
    |> assoc_constraint(:ingest_job)
  end

  def error_changeset(ingest_row, attrs) do
    ingest_row
    |> cast(attrs, [:field, :message])
  end

  def field_changeset(ingest_row, attrs) do
    ingest_row
    |> cast(attrs, [:header, :value])
  end

  def state_changeset(ingest_row, attrs) do
    ingest_row
    |> cast(attrs, [:state])
    |> validate_required([:ingest_job_id, :row])
    |> assoc_constraint(:ingest_job)
    |> validate_required([:state])
  end

  def data_changeset(ingest_row, _attrs) do
    ingest_row
    |> cast_embed(:errors, with: &error_changeset/2)
    |> cast_embed(:fields, with: &field_changeset/2)
    |> validate_required([:ingest_job_id, :row])
  end
end
