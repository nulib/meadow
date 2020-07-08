defmodule Meadow.Data.ControlledTerms do
  @moduledoc """
  Caching context for Controlled Terms
  """

  import Ecto.Query

  alias Meadow.Data.Schemas.ControlledTermCache
  alias Meadow.Repo

  @type cache_status :: :db | :memory | :miss
  @type controlled_term :: %{id: binary(), label: binary()}
  @type fetch_result :: {{:ok, cache_status()}, controlled_term()}

  @doc """
  Returns a cached term, fetching and storing it if necessary.

  ## Examples

      # Cache miss
      iex> fetch("http://id.loc.gov/authorities/names/n50034776")
      {{:ok, :miss},
        %{
          id: "http://id.loc.gov/authorities/names/n50034776",
          label: "Carver, George Washington, 1864?-1943"
        }}

      # Found in DB cache
      iex> fetch("http://id.loc.gov/authorities/names/n50034776")
      {{:ok, :db},
        %{
          id: "http://id.loc.gov/authorities/names/n50034776",
          label: "Carver, George Washington, 1864?-1943"
        }}

      # Found in ETS cache
      iex> fetch("http://id.loc.gov/authorities/names/n50034776")
      {{:ok, :memory},
        %{
          id: "http://id.loc.gov/authorities/names/n50034776",
          label: "Carver, George Washington, 1864?-1943"
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
        label: "Carver, George Washington, 1864?-1943"
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

      %ControlledTermCache{id: id, label: label} ->
        {{:ok, :db}, %{id: id, label: label}}
    end
  end

  defp cache(id) do
    Cachex.del!(Meadow.Cache.ControlledTerms, id)

    case Authoritex.fetch(id) do
      {:ok, %{id: id, label: label}} ->
        %ControlledTermCache{id: id}
        |> ControlledTermCache.changeset(%{label: label})
        |> Repo.insert_or_update()

        {:ok, %{id: id, label: label}}

      other ->
        other
    end
  end
end
