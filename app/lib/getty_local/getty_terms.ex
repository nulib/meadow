defmodule GettyLocal.GettyTerms do
  @moduledoc """
  Context module for querying Getty local authority records
  """

  alias GettyLocal.Schemas.GettyTerm
  alias Meadow.Repo
  import Ecto.Query

  def get_term(id) do
    GettyTerm
    |> where([t], t.uri == ^id)
    |> select([t], %{
      uri: t.uri,
      qualified_label: t.qualified_label,
      hint: t.hint,
      variants: fragment("string_to_array(?, '§')", t.variants)
    })
    |> Repo.one()
  end

  # The scoring fragment in the search_terms function are designed to prioritize results where
  # the query matches the beginning of the label, followed by matches anywhere in the label or
  # at the beginning of any variant, followed by matches anywhere in any variant.
  def search_terms(authority, query, max_results \\ 20) do
    contains_term = "%#{query}%"
    starts_with_term = "#{query}%"

    subquery =
      from(g in GettyTerm,
        where:
          g.authority == ^authority and
            (ilike(g.label, ^contains_term) or ilike(g.variants, ^contains_term)),
        select: %{
          uri: g.uri,
          qualified_label: g.qualified_label,
          hint: g.hint,
          label: g.label,
          variants: fragment("string_to_array(?, '§')", g.variants),
          score:
            fragment(
              """
              CASE
                WHEN ? ILIKE ? THEN 3
                WHEN ? ILIKE ? THEN 2
                WHEN ? ILIKE ? THEN 2
                WHEN ? ILIKE ? THEN 1
                ELSE 0
              END
              """,
              g.label,
              ^starts_with_term,
              g.label,
              ^contains_term,
              g.variants,
              ^starts_with_term,
              g.variants,
              ^contains_term
            )
        }
      )

    from(s in subquery(subquery),
      order_by: [desc: s.score, asc: s.label]
    )
    |> limit(^max_results)
    |> Repo.all()
  end
end
