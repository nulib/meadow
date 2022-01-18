defmodule NUL.Authority do
  @moduledoc "Authoritex implementation for Northwestern University Libraries local authority"
  @behaviour Authoritex

  import Ecto.Query

  alias Meadow.Repo
  alias NUL.Schemas.AuthorityRecord

  @id_prefix "info:nul"

  @impl Authoritex
  def can_resolve?(@id_prefix <> _), do: true
  def can_resolve?(_), do: false

  @impl Authoritex
  def code, do: "nul-authority"

  @impl Authoritex
  def description, do: "Northwestern University Libraries local authority"

  @impl Authoritex
  def fetch(id) do
    case get_record(id) do
      %{} = record -> {:ok, record}
      _ -> {:error, 404}
    end
  end

  @impl Authoritex
  def search(query, max_results \\ 30) do
    case get_records(query, max_results) do
      [] -> {:ok, []}
      [_ | _] = results -> {:ok, results}
      _ -> {:error, :nul_authority_search_error}
    end
  end

  defp get_record(id) do
    from(a in AuthorityRecord,
      select: %{
        id: a.id,
        label: a.label,
        qualified_label: fragment("concat_ws(' ', ?, ?)", a.label, a.hint),
        hint: a.hint,
        variants: []
      }
    )
    |> Repo.get(id)
  end

  defp get_records(query, max_results) do
    from(a in AuthorityRecord,
      where: ilike(a.label, ^"%#{query}%"),
      or_where: ilike(a.hint, ^"%#{query}%"),
      limit: ^max_results,
      select: %{id: a.id, label: a.label, hint: a.hint}
    )
    |> Repo.all()
  end
end
