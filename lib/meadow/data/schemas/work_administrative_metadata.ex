defmodule Meadow.Data.Schemas.WorkAdministrativeMetadata do
  @moduledoc """
  Administrative metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime_usec]
  embedded_schema do
    field :project_name, {:array, :string}, default: []
    field :project_desc, {:array, :string}, default: []
    field :project_proposer, {:array, :string}, default: []
    field :project_manager, {:array, :string}, default: []
    field :project_task_number, {:array, :string}, default: []
    field :project_cycle, :string

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [
      :project_name,
      :project_desc,
      :project_proposer,
      :project_manager,
      :project_task_number,
      :project_cycle
    ])

    # The following are marked as required on the metadata
    # spreadsheet, but commented out so that works can be
    # created without them from ingest sheets.
    #
    # |> validate_required([:project_cycle, :status])
    # |> validate_length(:project_name, min: 1)
    # |> validate_length(:project_proposer, min: 1)
    # |> validate_length(:project_manager, min: 1)
  end

  def field_names, do: __schema__(:fields) -- [:id, :inserted_at, :updated_at]

  defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.WorkAdministrativeMetadata do
    alias Meadow.Data.Schemas.WorkAdministrativeMetadata, as: Source

    def id(md), do: md.id
    def routing(_), do: false

    def encode(md) do
      Source.field_names()
      |> Enum.map(fn field_name ->
        {field_name, md |> Map.get(field_name)}
      end)
      |> Enum.into(%{})
    end
  end
end
