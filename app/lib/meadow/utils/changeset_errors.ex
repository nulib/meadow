defmodule Meadow.Utils.ChangesetErrors do
  @moduledoc """
  Traverses the changeset errors and returns a map of
  error messages. For example:

  %{title: ["can't be blank"], accession_number: ["must be unique"]}
  """
  alias Ecto.Changeset
  alias Meadow.Utils.Atoms

  def error_details(changeset) do
    Changeset.traverse_errors(changeset, &format_errors_with_values/3)
  end

  defp format_errors_with_values(%{params: params}, field, error) do
    with input <- params |> Map.get(to_string(field)) do
      %{value: format_value(input), error: format_error(error)}
    end
  end

  defp format_value(%{id: value}), do: value
  defp format_value(%{edtf: value}), do: value
  defp format_value(nil), do: nil
  defp format_value(value) when is_binary(value), do: value
  defp format_value(value), do: inspect(value)

  defp format_error({404, _opts}), do: "is an unknown identifier"
  defp format_error({:unknown_authority, _opts}), do: "is from an unknown authority"

  defp format_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      value =
        try do
          case {key, value} do
            {:type, {aggregate, type}} when is_atom(type) ->
              "#{aggregate} of #{type}"

            {:type, type} when is_atom(type) ->
              to_string(type)

            other ->
              to_string(other)
          end
        rescue
          Protocol.UndefinedError -> inspect(value)
        end

      String.replace(acc, "%{#{key}}", value)
    end)
  end

  def humanize_errors(errors, opts \\ [])

  def humanize_errors(%Changeset{} = errors, opts) do
    errors
    |> error_details()
    |> humanize_errors(opts)
  end

  def humanize_errors(errors, opts) do
    with errors <- errors |> Atoms.atomize() do
      {flattened, rest} =
        Keyword.get(opts, :flatten, [])
        |> Enum.map(&Atoms.atomize/1)
        |> Enum.flat_map_reduce(errors, fn field_to_flatten, acc ->
          {flatten_errors(Map.get(acc, field_to_flatten, [])), Map.delete(acc, field_to_flatten)}
        end)

      (flatten_errors(rest) ++ flattened) |> Enum.into(%{})
    end
  end

  defp flatten_errors([]), do: []

  defp flatten_errors(errors) when is_map(errors) do
    errors
    |> Enum.map(fn {field, value} -> flatten_errors({field, value}) end)
    |> List.flatten()
  end

  defp flatten_errors({field, [error]}), do: {to_string(field), humanize_error(error)}

  defp flatten_errors({field, value}) when is_list(value) do
    value
    |> Enum.with_index(1)
    |> Enum.map(fn {error, index} ->
      case humanize_error(error) do
        nil -> nil
        [] -> nil
        text -> {"#{field}##{index}", text}
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp flatten_errors(v) when is_list(v), do: Enum.map(v, &flatten_errors/1)

  defp flatten_errors(v), do: v

  # If the value is empty, just return the error
  defp humanize_error(%{error: error, value: []}), do: error
  defp humanize_error(%{error: error, value: ""}), do: error
  defp humanize_error(%{error: error, value: nil}), do: error

  # If the value is not empty, just return the value and the error
  defp humanize_error(%{error: error, value: input}),
    do: "#{input} #{error}"

  # Handle errors embedded in maps (e.g. %{role: role_error, term: term_error})
  defp humanize_error(errors) when is_map(errors) do
    errors
    |> Enum.map(fn {_, [error]} -> humanize_error(error) end)
  end

  # If the error is just a binary, return it
  defp humanize_error(v) when is_binary(v), do: v

  # If the error is anything else, discard it
  defp humanize_error(_), do: nil
end
