defmodule MeadowWeb.Schema.Types.ValueEntryScalar do
  @moduledoc """
  The `ValueEntry` scalar represents an identified repeating free-text metadata
  value: an object `{ id, value }`.

  This scalar is the *output* type only: each item serializes to `{ id, value }`
  so the editor can round-trip the stable `id` and preserve per-item identity
  across an edit, and — because it is a scalar — selecting one of these fields
  needs no subselection, so existing GraphQL documents are unchanged. Writes go
  through the `value_entry_input` input object, which gives malformed input a
  proper validation error.

  Absinthe still requires a `parse/1`, so it mirrors the input object's contract
  (`{ id?, value }`, plus a bare string as a new value) and rejects anything
  else, in case the scalar is ever used in an argument position.
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

  # An object literal/variable: exactly `{ id?, value }`, both strings (a null id
  # is tolerated and treated as absent, since clients serialize new items that
  # way). Anything else — an unknown field, a non-string value — is a parse
  # error rather than silently dropped: this scalar carries identity, and a
  # mistyped field must not quietly discard an id and remint it on save.
  defp parse_value_entry(%Input.Object{fields: fields}) do
    fields
    |> Enum.reduce_while({:ok, %{}}, fn field, {:ok, acc} ->
      case parse_object_field(field) do
        {:ok, nil} -> {:cont, {:ok, acc}}
        {:ok, {name, value}} -> {:cont, {:ok, Map.put(acc, name, value)}}
        :error -> {:halt, :error}
      end
    end)
    |> validate_entry()
  end

  defp parse_value_entry(_), do: :error

  defp parse_object_field(%{name: name, input_value: %{normalized: normalized}})
       when name in ["id", "value"] do
    case normalized do
      %Input.String{value: value} -> {:ok, {name, value}}
      %Input.Null{} when name == "id" -> {:ok, nil}
      _ -> :error
    end
  end

  defp parse_object_field(_field), do: :error

  defp validate_entry({:ok, %{"value" => _} = entry}), do: {:ok, entry}
  defp validate_entry(_), do: :error
end
