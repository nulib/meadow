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

  def validate_trimmed(%Ecto.Changeset{} = change, field) do
    validate_change(change, field, fn _, value ->
      if String.trim(value) == value,
        do: [],
        else: [{field, "cannot have leading or trailing spaces"}]
    end)
  end
end
