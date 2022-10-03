defmodule Meadow.Indexing.V1.WorkAdministrativeMetadata do
  @moduledoc """
  v1 encoding for WorkAdministrativeMetadata
  """

  alias Meadow.Data.Schemas.WorkAdministrativeMetadata, as: Source

  def encode(md) do
    %{
      administrativeMetadata:
        Source.field_names()
        |> Enum.map(fn field_name ->
          {Inflex.camelize(field_name, :lower) |> String.to_atom(), md |> Map.get(field_name)}
        end)
        |> Enum.into(%{})
    }
  end
end
