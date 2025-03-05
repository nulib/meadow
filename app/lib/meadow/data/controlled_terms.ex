defmodule Meadow.Data.ControlledTerms do
  @moduledoc """
  Caching context for Controlled Terms
  """

  import Ecto.Query

  alias Meadow.Data.Schemas.ControlledTermCache
  alias Meadow.Repo

  require Logger

  @type cache_status :: :db | :memory | :miss
  @type controlled_term :: %{id: binary(), label: binary(), variants: binary()}
  @type fetch_result :: {{:ok, cache_status()}, controlled_term()}

  @doc """
  Returns a cached term, fetching and storing it if necessary.

  ## Examples

      # Cache miss
      iex> fetch("http://id.loc.gov/authorities/names/n50034776")
      {{:ok, :miss},
        %{
          id: "http://id.loc.gov/authorities/names/n50034776",
          label: "Carver, George Washington, 1864?-1943",
          variants: ["Kārvar, Jārji Vāṣiṅgṭan, 1864?-1943",
          "Carver, George, 1864?-1943"]
        }}

      # Found in DB cache
      iex> fetch("http://id.loc.gov/authorities/names/n50034776")
      {{:ok, :db},
        %{
          id: "http://id.loc.gov/authorities/names/n50034776",
          label: "Carver, George Washington, 1864?-1943",
          variants: ["Kārvar, Jārji Vāṣiṅgṭan, 1864?-1943",
          "Carver, George, 1864?-1943"]
        }}

      # Found in ETS cache
      iex> fetch("http://id.loc.gov/authorities/names/n50034776")
      {{:ok, :memory},
        %{
          id: "http://id.loc.gov/authorities/names/n50034776",
          label: "Carver, George Washington, 1864?-1943",
          variants: ["Kārvar, Jārji Vāṣiṅgṭan, 1864?-1943",
          "Carver, George, 1864?-1943"]
        }}

      # Error
      iex> fetch("invalid_id")
      {:error, :unknown_authority}
  """
  @spec fetch(id :: binary()) :: fetch_result() | {:error, any()}
  def fetch(id), do: ets_fetch(id)

  @doc """
  Like fetch/1, but raises on error

  ## Examples

      iex> fetch!("http://id.loc.gov/authorities/names/n50034776")
      %{
        id: "http://id.loc.gov/authorities/names/n50034776",
        label: "Carver, George Washington, 1864?-1943",
          variants: ["Kārvar, Jārji Vāṣiṅgṭan, 1864?-1943",
          "Carver, George, 1864?-1943"]
      }

      # Error
      iex> fetch!("invalid_id")
      ** (RuntimeError) Error fetching controlled term `invalid_id': unknown_authority
  """
  @spec fetch!(id :: binary()) :: controlled_term()
  def fetch!(id) do
    case fetch(id) do
      {{:ok, _}, term} -> term
      {:error, error} -> raise "Error fetching controlled term `#{id}': #{error}"
    end
  end

  @doc """
  Clears the entire cache
  """
  @spec clear!() :: :ok | {:error, any()}
  def clear! do
    Cachex.clear!(Meadow.Cache.ControlledTerms)
    Repo.delete_all(ControlledTermCache)
  end

  @doc """
  Clears a single ID from the cache
  """
  @spec clear!(id :: binary()) :: :ok | {:error, any()}
  def clear!(id) do
    Cachex.del!(Meadow.Cache.ControlledTerms, id)

    from(e in ControlledTermCache, where: e.id == ^id)
    |> Repo.delete_all()
  end

  @doc """
  Deletes values from the cache based on age in seconds and (optional) ID prefix

  ## Examples

      # Clear all entries older than 24 hours
      iex> clear!(86_400)
      :ok

      # Clear all LCNAF entries older than 24 hours
      iex> clear!(86_400, "http://id.loc.gov/authorities/names/")
      :ok
  """
  @spec expire!(age_in_seconds :: integer(), prefix :: binary()) :: :ok | {:error, any()}
  def expire!(age_in_seconds, prefix \\ "") do
    Cachex.clear!(Meadow.Cache.ControlledTerms)

    with timestamp <- NaiveDateTime.utc_now() |> NaiveDateTime.add(-age_in_seconds) do
      from(e in ControlledTermCache,
        where: e.updated_at < ^timestamp,
        where: like(e.id, ^(prefix <> "%"))
      )
      |> Repo.delete_all()
    end
  end

  def cache!(%{id: id, label: label, variants: variants}) do
    %ControlledTermCache{id: id}
    |> ControlledTermCache.changeset(%{label: label, variants: variants})
    |> Repo.insert(on_conflict: :replace_all, conflict_target: :id)
  end

  @doc """
  Test two controlled terms to see if they share a common term and role

  ## Examples

      iex> term_1 = %{role: %{id: "aut", scheme: "marc_relator"}, term: %{id: "http://id.loc.gov/authorities/names/n50034776", label: "Carver, George Washington, 1864?-1943"}}
      iex> term_2 = %{role: %{id: "pub", scheme: "marc_relator"}, term: "http://id.loc.gov/authorities/names/n50034776"}
      iex> term_3 = %{role: nil, term: "http://id.loc.gov/authorities/names/n50034776"}
      iex> term_4 = %{role: %{id: "aut", scheme: "marc_relator"}, term: "http://id.loc.gov/authorities/names/no2011087251"}
      iex> term_5 = %{role: %{id: "aut", scheme: "marc_relator"}, term: %{id: "http://id.loc.gov/authorities/names/no2011087251"}}
      iex> terms_equal?(term_1, term_1)
      true
      iex> terms_equal?(term_3, term_3)
      true
      iex> terms_equal?(term_1, term_2)
      false
      iex> terms_equal?(term_1, term_3)
      false
      iex> terms_equal?(term_1, term_4)
      false
      iex> terms_equal?(term_4, term_5)
      true
  """
  def terms_equal?(a, b) do
    with term_a <- term_id(a.term),
         role_a <- Map.get(a, :role),
         term_b <- term_id(b.term),
         role_b <- Map.get(b, :role) do
      if is_nil(role_a) do
        is_nil(role_b) and term_a == term_b
      else
        if is_nil(role_b) do
          false
        else
          role_a.scheme == role_b.scheme and
            role_a.id == role_b.id and
            term_a == term_b
        end
      end
    end
  end

  defp term_id(%{id: id}), do: id

  defp term_id(term), do: term

  defp ets_fetch(id) do
    case Cachex.get!(Meadow.Cache.ControlledTerms, id) do
      nil ->
        case db_fetch(id) do
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
    do: Cachex.put!(Meadow.Cache.ControlledTerms, term.id, term)

  defp db_fetch(id) do
    case Repo.get(ControlledTermCache, id) do
      nil ->
        case cache(id) do
          {:ok, term} -> {{:ok, :miss}, term}
          other -> other
        end

      %ControlledTermCache{id: id, label: label, variants: variants} ->
        {{:ok, :db}, %{id: id, label: label, variants: variants}}
    end
  end

  defp cache(id) do
    Cachex.del!(Meadow.Cache.ControlledTerms, id)

    case Authoritex.fetch(id) do
      {:ok, %{id: id, label: label, variants: variants}} ->
        try_to_save(id, label, variants)
        {:ok, %{id: id, label: label, variants: variants}}

      other ->
        other
    end
  end

  defp try_to_save(id, label, variants) do
    %ControlledTermCache{id: id}
    |> ControlledTermCache.changeset(%{label: label, variants: variants})
    |> Repo.insert(on_conflict: :nothing)
  rescue
    e in Postgrex.Error ->
      Logger.warning("Unable to cache label and/or variants for #{id}: #{e.postgres.message}")
  end

  def extract_unique_terms(data) do
    data
    |> extract_all_terms()
    |> Enum.to_list()
    |> List.flatten()
    |> Enum.uniq()
  end

  defp extract_all_terms(data), do: data |> extract_terms()

  defp extract_terms(%Stream{} = stream), do: Stream.flat_map(stream, &extract_all_terms/1)
  defp extract_terms(%{term: %{id: uri}}), do: [uri]
  defp extract_terms(data) when is_list(data), do: Enum.flat_map(data, &extract_all_terms/1)
  defp extract_terms(data) when is_map(data), do: Map.values(data) |> extract_all_terms()
  defp extract_terms(_), do: []
end
