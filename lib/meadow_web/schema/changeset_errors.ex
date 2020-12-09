defmodule MeadowWeb.Schema.ChangesetErrors do
  @moduledoc """
  Traverses the changeset errors and returns a map of
  error messages. For example:

  %{title: ["can't be blank"], accession_number: ["must be unique"]}
  """
  def error_details(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &format_error/1)
  end

  defp format_error({404, _opts}) do
    "identifier not found in authority"
  end

  defp format_error({msg, opts}) when is_atom(msg) do
    with msg <- msg |> to_string() |> String.replace("_", " ") do
      format_error({msg, opts})
    end
  end

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
end
