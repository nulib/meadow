defmodule Meadow.Data.Schemas.WorkDescriptiveMetadata do
  @moduledoc """
  Descriptive metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  # {field_name, repeating}
  @fields [
    {:abstract, true},
    {:alternate_title, true},
    {:ark, false},
    {:box_name, true},
    {:box_number, true},
    {:call_number, true},
    {:caption, true},
    {:catalog_key, true},
    {:citation, true},
    {:description, true},
    {:folder_name, true},
    {:folder_number, true},
    {:identifier, true},
    {:keywords, true},
    {:legacy_identifier, true},
    {:notes, true},
    {:nul_use_statement, false},
    {:physical_description_material, true},
    {:physical_description_size, true},
    {:provenance, true},
    {:publisher, true},
    {:related_material, true},
    {:related_url, true},
    {:rights_holder, true},
    {:scope_and_contents, true},
    {:series, true},
    {:source, true},
    {:table_of_contents, true},
    {:title, false}
  ]

  @timestamps_opts [type: :utc_datetime_usec]
  embedded_schema do
    @fields
    |> Enum.each(fn
      {f, true} -> field f, {:array, :string}, default: []
      {f, false} -> field f, :string
    end)

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, field_names())

    # The following are marked as required on the metadata
    # spreadsheet, but commented out so that works can be
    # created without them from ingest sheets.
    #
    # |> validate_required([:ark, :nul_use_statement, :title])
  end

  def field_names, do: __schema__(:fields) -- [:id, :inserted_at, :updated_at]

  defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.WorkDescriptiveMetadata do
    alias Meadow.Data.Schemas.WorkDescriptiveMetadata, as: Source

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
