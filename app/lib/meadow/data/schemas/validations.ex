defmodule Meadow.Data.Schemas.Validations do
  @moduledoc """
  This module provides custom changeset functions and
  validations
  """

  @doc """
  If a `cast_embed()` will result in a `nil` value (either on create or
  update), set it to an empty embedded struct instead
  """
  def prepare_embed(%Ecto.Changeset{data: data, params: params} = change, field)
      when is_atom(field) do
    with f <- to_string(field),
         current <- Enum.find([field, f], &Map.get(data, &1)) do
      value =
        cond do
          Map.has_key?(params, f) and is_nil(Map.get(params, f)) -> empty_struct(data, field)
          Map.has_key?(params, f) -> Map.get(params, f)
          is_nil(current) -> empty_struct(data, field)
          true -> nil
        end

      case value do
        nil ->
          change

        value ->
          params = Map.put(params, f, value)
          Map.put(change, :params, params)
      end
    end
  end

  defp empty_struct(data, field) do
    field_spec =
      case data.__struct__.__schema__(:type, field) do
        {:parameterized, _type, f} -> f
        {:parameterized, {_type, f}} -> f
      end

    field_spec.related.__struct__ |> Map.from_struct()
  end
end
