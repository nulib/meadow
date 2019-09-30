defmodule Meadow.Ingest.IngestSheets.IngestSheetWorks do
  @moduledoc """
  Links ingest sheets to works
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type Ecto.ULID
  schema "ingest_sheet_works" do
    belongs_to(:ingest_sheet, Meadow.Ingest.IngestSheets.IngestSheet, primary_key: true)
    belongs_to(:work, Meadow.Data.Works.Work, primary_key: true)
  end

  @doc false
  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:ingest_sheet, :work])
    |> validate_required([:ingest_sheet, :work])
  end
end
