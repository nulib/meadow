defmodule Meadow.Ingest.IngestJobs.IngestJob do
  @moduledoc """
  IngestJob represents an inventory sheet upload
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Meadow.Repo

  @default_state [
    %{name: "file", state: "pending"},
    %{name: "rows", state: "pending"},
    %{name: "overall", state: "pending"}
  ]

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "ingest_jobs" do
    field :name, :string
    field :filename, :string
    field :file_errors, {:array, :string}, default: []

    embeds_many :state, State, primary_key: {:name, :string, []} do
      field :state, :string
    end

    belongs_to :project, Meadow.Ingest.Projects.Project
    has_many :ingest_rows, Meadow.Ingest.IngestJobs.IngestRow

    timestamps()
  end

  @doc false
  def changeset(ingest_job, attrs) do
    attrs =
      if ingest_job.state in [nil, []],
        do: Map.put_new(attrs, :state, @default_state),
        else: attrs

    ingest_job
    |> cast(attrs, [:name, :filename, :project_id, :file_errors])
    |> cast_embed(:state, with: &state_changeset/2)
    |> validate_required([:name, :filename, :project_id])
    |> assoc_constraint(:project)
    |> unique_constraint(:name)
  end

  def state_changeset(ingest_job, attrs) do
    ingest_job
    |> cast(attrs, [:name, :state])
  end

  def reset_default_state(ingest_job) do
    ingest_job
    |> changeset(%{state: @default_state})
    |> Repo.update()
  end

  def find_state(ingest_job, key \\ "overall") do
    ingest_job.state
    |> Enum.reduce_while(nil, fn state, result ->
      case state.name do
        ^key -> {:halt, state.state}
        _ -> {:cont, result}
      end
    end)
  end
end
