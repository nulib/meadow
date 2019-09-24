defmodule Meadow.Ingest.IngestSheets.IngestSheet do
  @moduledoc """
  IngestSheet represents an ingest sheet upload
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
  schema "ingest_sheets" do
    field :name, :string
    field :filename, :string
    field :file_errors, {:array, :string}, default: []

    embeds_many :state, State, primary_key: {:name, :string, []} do
      field :state, :string
    end

    belongs_to :project, Meadow.Ingest.Projects.Project
    has_many :ingest_sheet_rows, Meadow.Ingest.IngestSheets.IngestSheetRow

    timestamps()
  end

  @doc false
  def changeset(ingest_sheet, attrs) do
    attrs =
      if ingest_sheet.state in [nil, []],
        do: Map.put_new(attrs, :state, @default_state),
        else: attrs

    ingest_sheet
    |> cast(attrs, [:name, :filename, :project_id, :file_errors])
    |> cast_embed(:state, with: &state_changeset/2)
    |> validate_required([:name, :filename, :project_id])
    |> assoc_constraint(:project)
    |> unique_constraint(:name)
  end

  def state_changeset(ingest_sheet, attrs) do
    ingest_sheet
    |> cast(attrs, [:name, :state])
  end

  def reset_default_state(ingest_sheet) do
    ingest_sheet
    |> changeset(%{state: @default_state})
    |> Repo.update()
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
