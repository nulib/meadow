defmodule MeadowWeb.Schema.Types.ValueEntryScalar do
  @moduledoc """
  The `ValueEntry` scalar represents an identified repeating free-text metadata
  value: an object `{ id, value }`.

  On output each item serializes to `{ id, value }` so the editor can round-trip
  the stable `id` and preserve per-item identity across an edit. On input a bare
  string is also accepted and treated as a new value (the changeset mints an id),
  so callers that still send plain strings — CSV, the AI apply path, older
  clients — keep working unchanged.

  Because it is a scalar, selecting one of these fields needs no subselection, so
  existing GraphQL documents are unchanged; only the shape of the returned value
  goes from a string to a `{ id, value }` object.
  """
  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint.Input
  alias Meadow.Data.Schemas.ValueEntry

  scalar :value_entry, name: "ValueEntry" do
    description("An identified free-text metadata value ({ id, value }). A bare string is accepted on input.")
    serialize(&serialize_value_entry/1)
    parse(&parse_value_entry/1)
  end

  defp serialize_value_entry(%ValueEntry{id: id, value: value}), do: %{id: id, value: value}
  defp serialize_value_entry(%{value: _} = map), do: map
  defp serialize_value_entry(%{"value" => _} = map), do: map
  defp serialize_value_entry(value) when is_binary(value), do: %{id: nil, value: value}
  defp serialize_value_entry(_), do: nil

  # A bare string literal/variable: a new value.
  defp parse_value_entry(%Input.String{value: value}), do: {:ok, %{"value" => value}}
  defp parse_value_entry(%Input.Null{}), do: {:ok, nil}

  # An object literal/variable: preserve any supplied id so identity survives.
  defp parse_value_entry(%Input.Object{fields: fields}) do
    {:ok, Enum.reduce(fields, %{}, &put_object_field/2)}
  end

  defp parse_value_entry(_), do: :error

  defp put_object_field(%{name: name, input_value: %{normalized: %Input.String{value: value}}}, acc),
    do: Map.put(acc, name, value)

  defp put_object_field(_field, acc), do: acc
end
