defmodule Meadow.Data.Schemas.Validations do
  @moduledoc """
  This module provides custom changeset functions and
  validations
  """

  import Ecto.Changeset
  alias Ecto.Association.NotLoaded

  @doc """
  Make sure a one-to-one metadata association always has a row: if the parent
  has no current row and the params do not mention the association (or set it
  to nil), inject empty params so `cast_assoc` builds one.
  """
  def prepare_assoc(%Ecto.Changeset{data: data, params: params} = change, field)
      when is_atom(field) do
    f = to_string(field)

    if needs_empty_params?(fetch_param(params, field, f), current_value(data, field)) do
      %{change | params: params |> Map.delete(field) |> Map.put(f, %{})}
    else
      change
    end
  end

  # nil params or no params with no current row: build an empty row
  defp needs_empty_params?({:ok, nil}, _current), do: true
  defp needs_empty_params?({:ok, _params}, _current), do: false
  defp needs_empty_params?(:error, nil), do: true
  defp needs_empty_params?(:error, _current), do: false

  defp fetch_param(params, field, f) do
    cond do
      Map.has_key?(params, f) -> {:ok, Map.get(params, f)}
      Map.has_key?(params, field) -> {:ok, Map.get(params, field)}
      true -> :error
    end
  end

  defp current_value(data, field) do
    case Map.get(data, field) do
      %NotLoaded{} -> nil
      value -> value
    end
  end

  @doc """
  Embedded-schema counterpart of `prepare_assoc/2` (still used by FileSet's
  jsonb embeds): if a `cast_embed()` would result in a `nil` value, use an
  empty embedded struct instead.
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

    field_spec.related.__struct__() |> Map.from_struct()
  end

  def validate_trimmed(%Ecto.Changeset{} = change, field) do
    validate_change(change, field, fn _, value ->
      if String.trim(value) == value,
        do: [],
        else: [{field, "cannot have leading or trailing spaces"}]
    end)
  end
end
