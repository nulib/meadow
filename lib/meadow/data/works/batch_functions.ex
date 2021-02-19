defmodule Meadow.Data.Works.BatchFunctions do
  @moduledoc """
  Build batch replace functions for different metadata fields. This is necessary
  because Ecto.Query.fragment() doesn't allow interpolation for its first argument
  to prevent SQL injection attacks
  """

  @schemas ~w(descriptive_metadata administrative_metadata)a

  defmacro __using__(_) do
    batch_functions =
      Enum.map(@schemas, fn schema ->
        quote do
          @doc """
          Batch update controlled #{unquote(schema)} values
          """
          def replace_controlled_value(query, unquote(schema), field_name, remove, add) do
            to_remove = simplify_terms(remove)
            to_add = simplify_terms(add)

            from query,
              update: [
                set: [
                  {unquote(schema),
                   fragment(
                     unquote("replace_controlled_value(#{schema}, ?::text, ?::jsonb, ?::jsonb)"),
                     ^field_name,
                     ^to_remove,
                     ^to_add
                   )},
                  {:updated_at, ^DateTime.utc_now()}
                ]
              ]
          end

          @doc """
          Merge map of values into #{unquote(schema)}
          """
          def merge_metadata_values(query, unquote(schema), values, mode) do
            from query,
              update: [
                set: [
                  {unquote(schema),
                   fragment(
                     unquote("merge_jsonb_values(#{schema}, ?::jsonb, ?::text)"),
                     ^values,
                     ^to_string(mode)
                   )}
                ]
              ]
          end
        end
      end)

    simplify_functions =
      quote do
        defp simplify_terms(nil), do: []
        defp simplify_terms([]), do: []
        defp simplify_terms([term | terms]), do: [simplify_term(term) | simplify_terms(terms)]

        defp simplify_term(%{role: role, term: %{id: id}}), do: %{role: role, term: id}
        defp simplify_term(term), do: term
      end

    [simplify_functions | batch_functions]
  end
end
