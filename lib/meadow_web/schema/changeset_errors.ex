defmodule MeadowWeb.Schema.ChangesetErrors do
  @doc """
  Traverses the changeset errors and returns a map of
  error messages. For example:

  %{title: ["can't be blank"], accession_number: ["must be unique"]}
  """
  def error_details(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
