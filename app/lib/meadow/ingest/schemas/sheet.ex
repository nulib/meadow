defmodule Meadow.Ingest.Schemas.Sheet do
  @moduledoc """
  Sheet represents an ingest sheet upload
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Meadow.Data.Schemas.MultiValued
  alias Meadow.Ingest.Schemas.SheetState
  alias Meadow.Repo

  # Stage states, in the order they are preloaded (by name)
  @default_state [
    %{name: "file", state: "pending"},
    %{name: "overall", state: "pending"},
    %{name: "rows", state: "pending"}
  ]

  @statuses ~w(uploaded file_fail row_fail valid generating_preview awaiting_approval approved completed completed_error deleted)

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ingest_sheets" do
    field :title, :string
    field :filename, :string
    field :status, :string, default: "uploaded"
    field :ai_ingest, :boolean, default: false
    field :ai_cost_actual, :float, default: 0.0
    field :ai_cost_estimate, :float, default: 0.0
    field :ai_preview, {:array, :map}, default: []
    field :file_errors, {:array, :string}, default: []

    has_many :state, SheetState,
      foreign_key: :sheet_id,
      preload_order: [asc: :name],
      on_replace: :delete

    belongs_to :project, Meadow.Ingest.Schemas.Project
    has_many :ingest_sheet_rows, Meadow.Ingest.Schemas.Row

    has_many :works, Meadow.Data.Schemas.Work, foreign_key: :ingest_sheet_id

    timestamps()
  end

  @doc false
  def changeset(ingest_sheet, attrs) do
    ingest_sheet = preload_state(ingest_sheet)

    attrs =
      case ingest_sheet.state do
        %Ecto.Association.NotLoaded{} -> Map.put_new(attrs, :state, @default_state)
        empty when empty in [nil, []] -> Map.put_new(attrs, :state, @default_state)
        _ -> attrs
      end

    ingest_sheet
    |> cast(attrs, [
      :title,
      :filename,
      :project_id,
      :file_errors,
      :status,
      :ai_ingest,
      :ai_cost_actual,
      :ai_cost_estimate,
      :ai_preview,
      :updated_at
    ])
    |> cast_state()
    |> cast_assoc(:works)
    |> validate_required([:title, :filename, :project_id])
    |> assoc_constraint(:project)
    |> unique_constraint(:title)
  end

  def status_changeset(ingest_sheet, attrs) do
    ingest_sheet
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_status()
  end

  # Stage rows are matched by name so a state update keeps the same rows
  defp cast_state(changeset),
    do:
      MultiValued.cast_entries(changeset, :state,
        with: &SheetState.changeset/3,
        key: &Map.get(&1, :name)
      )

  @doc "Preload the state rows of a persisted sheet if they are not loaded yet"
  def preload_state(
        %__MODULE__{__meta__: %{state: :loaded}, state: %Ecto.Association.NotLoaded{}} = sheet
      ),
      do: Repo.preload(sheet, :state)

  def preload_state(sheet), do: sheet

  def preloads, do: [:state]

  def file_errors_changeset(ingest_sheet, attrs) do
    ingest_sheet
    |> cast(attrs, [:file_errors])
    |> validate_required([:file_errors])
  end

  def reset_default_state(ingest_sheet) do
    ingest_sheet
    |> changeset(%{state: @default_state})
    |> Repo.update()
  end

  def validate_status(changeset) do
    case changeset.valid? do
      true ->
        status = get_field(changeset, :status)

        case Enum.member?(@statuses, status) do
          true ->
            changeset

          _ ->
            add_error(changeset, :status, "is not a valid status")
        end

      _ ->
        changeset
    end
  end

  def find_state(ingest_sheet, key \\ "overall") do
    ingest_sheet
    |> preload_state()
    |> Map.get(:state)
    |> Enum.reduce_while(nil, fn state, result ->
      case state.name do
        ^key -> {:halt, state.state}
        _ -> {:cont, result}
      end
    end)
  end
end
