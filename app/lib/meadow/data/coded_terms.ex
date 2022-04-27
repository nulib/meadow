defmodule Meadow.Data.CodedTerms do
  @moduledoc "Functions for retrieving coded terms and term lists"

  alias Meadow.Data.Schemas.CodedTerm
  alias Meadow.Repo

  import Ecto.Query

  require Logger

  @doc """
  List all coded term schemes

  Example:
    iex> Meadow.Data.CodedTerms.list_schemes()
    ["authority", "license", "marc_relator", "preservation_level",
     "rights_statement", "status", "subject_role", "visibility", "work_type"]
  """
  def list_schemes do
    from(ct in CodedTerm, distinct: ct.scheme, select: [:scheme])
    |> Repo.all()
    |> Enum.map(& &1.scheme)
  end

  @doc """
  List all coded terms in a scheme

  Examples:
    iex> Meadow.Data.CodedTerms.list_coded_terms("visibility")
    [
      %Meadow.Data.Schemas.CodedTerm{
        id: "AUTHENTICATED",
        label: "Institution",
        scheme: "visibility"
      },
      %Meadow.Data.Schemas.CodedTerm{
        id: "RESTRICTED",
        label: "Private",
        scheme: "visibility"
      },
      %Meadow.Data.Schemas.CodedTerm{
        id: "OPEN",
        label: "Public",
        scheme: "visibility"
      }
    ]

    iex> Meadow.Data.CodedTerms.list_coded_terms("non_existent_scheme")
    []
  """
  def list_coded_terms(scheme) do
    with scheme <- normalize(scheme) do
      from(ct in CodedTerm,
        where: ct.scheme == ^scheme,
        order_by: ct.label
      )
      |> Repo.all()
    end
  end

  @doc """
  Retrieve a coded term by id and scheme

  Example:
    iex> Meadow.Data.CodedTerms.get_coded_term("OPEN", "visibility")
    %Meadow.Data.Schemas.CodedTerm{
      id: "OPEN",
      label: "Public",
      scheme: "visibility"
    }

    iex> Meadow.Data.CodedTerms.get_coded_term("NAH", "visibility")
    nil

    iex> Meadow.Data.CodedTerms.get_coded_term("OPEN", "invisibility")
    nil
  """
  def get_coded_term(id, scheme), do: ets_fetch(id, scheme)

  def label(id, scheme) do
    case get_coded_term(id, scheme) do
      nil ->
        nil

      {{:ok, _}, term} ->
        term.label
    end
  end

  def seed(file) do
    with scheme <- Path.basename(file, ".json") do
      Logger.info("Seeding #{scheme} scheme from #{file}")
      seed_time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      data =
        File.read!(file)
        |> Jason.decode!(keys: :atoms)
        |> Enum.map(fn term ->
          Map.merge(term, %{scheme: scheme, inserted_at: seed_time, updated_at: seed_time})
        end)

      Repo.insert_all(CodedTerm, data, on_conflict: :replace_all, conflict_target: [:id, :scheme])
    end
  end

  defp normalize(scheme), do: scheme |> to_string |> String.downcase()

  defp ets_fetch(id, scheme) do
    case Cachex.get!(Meadow.Cache.CodedTerms, cache_key(id, scheme)) do
      nil ->
        case db_fetch(id, scheme) do
          {{:ok, _}, term} = result ->
            ets_store(term)
            result

          other ->
            other
        end

      term ->
        {{:ok, :memory}, term}
    end
  end

  defp ets_store(term),
    do: Cachex.put!(Meadow.Cache.CodedTerms, cache_key(term.id, term.scheme), term)

  defp db_fetch(id, scheme) do
    case term_query(id, scheme) do
      nil ->
        nil

      %CodedTerm{id: id, label: label, scheme: scheme} ->
        {{:ok, :db}, %{id: id, label: label, scheme: scheme}}
    end
  end

  defp term_query(id, scheme) do
    with scheme <- normalize(scheme) do
      from(ct in CodedTerm,
        where: ct.scheme == ^scheme and ct.id == ^id,
        order_by: ct.label
      )
      |> Repo.one()
    end
  end

  defp cache_key(id, scheme), do: scheme <> ":" <> id
end
