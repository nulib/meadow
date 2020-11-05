defmodule MeadowWeb.Schema.ChangesetErrors do
  @moduledoc """
  Traverses the changeset errors and returns a map of
  error messages. For example:

  %{title: ["can't be blank"], accession_number: ["must be unique"]}
  """
  def error_details(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        value =
          try do
            case {key, value} do
              {:type, {aggregate, type}} when is_atom(type) -> "#{aggregate} of #{type}"
              {:type, type} when is_atom(type) -> to_string(type)
              other -> to_string(other)
            end
          rescue
            Protocol.UndefinedError -> inspect(value)
          end

        String.replace(acc, "%{#{key}}", value)
      end)
    end)
  end
end
