defmodule Meadow.Data.Schemas.Validations do
  @moduledoc """
  This module provides custom changeset functions and
  validations
  """

  @doc """
  If a `cast_embed()` will result in a `nil` value (either on create or
  update), set it to an empty embedded struct instead
  """
  def prepare_embed(%Ecto.Changeset{data: data, params: params} = change, field) when is_atom(field) do
    with f <- to_string(field) do
      case {Map.get(params, f), Map.get(data, f)} do
        {nil, nil} ->
          {:embed, field_spec} = change.data.__struct__.__schema__(:type, field)
          params = Map.put(params, f, field_spec.related.__struct__ |> Map.from_struct())
          Map.put(change, :params, params)

        _ ->
          change
      end
    end
  end
end
