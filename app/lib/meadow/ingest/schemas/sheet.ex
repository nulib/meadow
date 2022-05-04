defmodule Meadow.Ingest.Schemas.Sheet do
  @moduledoc """
  Sheet represents an ingest sheet upload
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Meadow.Repo

  @default_state [
    %{name: "file", state: "pending"},
    %{name: "rows", state: "pending"},
    %{name: "overall", state: "pending"}
  ]

  @statuses ~w(uploaded file_fail row_fail valid approved completed completed_error deleted)

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ingest_sheets" do
    field :title, :string
    field :filename, :string
    field :status, :string, default: "uploaded"
    field :file_errors, {:array, :string}, default: []

    embeds_many :state, State, primary_key: {:name, :string, []} do
      field :state, :string
    end

    belongs_to :project, Meadow.Ingest.Schemas.Project
    has_many :ingest_sheet_rows, Meadow.Ingest.Schemas.Row

    has_many :works, Meadow.Data.Schemas.Work, foreign_key: :ingest_sheet_id

    timestamps()
  end

  @doc false
  def changeset(ingest_sheet, attrs) do
    attrs =
      if ingest_sheet.state in [nil, []],
        do: Map.put_new(attrs, :state, @default_state),
        else: attrs

    ingest_sheet
    |> cast(attrs, [:title, :filename, :project_id, :file_errors, :status, :updated_at])
    |> cast_embed(:state, with: &state_changeset/2)
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

  def state_changeset(ingest_sheet, attrs) do
    ingest_sheet
    |> cast(attrs, [:name, :state])
  end

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
    ingest_sheet.state
    |> Enum.reduce_while(nil, fn state, result ->
      case state.name do
        ^key -> {:halt, state.state}
        _ -> {:cont, result}
      end
    end)
  end
end
