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
  end

  def field_names, do: @fields |> Enum.map(fn {f, _} -> f end)
end
