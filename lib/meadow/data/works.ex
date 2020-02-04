defmodule Meadow.Data.Works do
  @moduledoc """
  The Works context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.Work
  alias Meadow.Repo

  @doc """
  Returns the list of Works.

  ## Examples

      iex> list_works()
      [%Work{}, ...]

  """
  def list_works do
    Repo.all(Work)
  end

  @doc """
  Returns a list of works matching the given `criteria`.

  Example Criteria:

  [{:limit, 15}, {:order, :asc}, {:filter, [{:visibility, :open}, {:work_type, :image}]}]
  """

  def list_works(criteria) do
    query = from(w in Work)

    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from w in query, limit: ^limit

      {:filter, filters}, query ->
        filter_with(filters, query)

      {:order, order}, query ->
        from p in query, order_by: [{^order, :id}]
    end)
    |> Repo.all()
  end

  defp filter_with(filters, query) do
    Enum.reduce(filters, query, fn
      {:matching, term}, query ->
        map = %{"title" => term}

        from q in query,
          where: fragment("descriptive_metadata @> ?::jsonb", ^map)

      {:visibility, value}, query ->
        from q in query, where: q.visibility == ^value

      {:work_type, value}, query ->
        from q in query, where: q.work_type == ^value
    end)
  end

  @doc """
  Gets a work.

  Raises `Ecto.NoResultsError` if the Work does not exist.

  ## Examples

      iex> get_work!("123")
      %Work{}

      iex> get_work!("456")
      ** (Ecto.NoResultsError)

  """
  def get_work!(id), do: Repo.get!(Work, id)

  @doc """
  Gets a work by accession_number

  Raises `Ecto.NoResultsError` if the Work does not exist
  """
  def get_work_by_accession_number!(accession_number) do
    Repo.get_by!(Work, accession_number: accession_number)
  end

  @doc """
  Check if accession number already exists in system

  iex> accession_exists?("123")
  true
  """
  def accession_exists?(accession_number) do
    Repo.exists?(from w in Work, where: w.accession_number == ^accession_number)
  end

  @doc """
  Creates a work.

  ## Examples

      iex> create_work(%{field: value})
      {:ok, %Meadow.Data.Schemas.Work{}}

      iex> create_work(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_work(attrs \\ %{}) do
    %Work{}
    |> Work.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Same as create_work/1 but raises on error
  """
  def create_work!(attrs \\ %{}) do
    %Work{}
    |> Work.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a work inside a transaction.
  """
  def ensure_create_work(attrs \\ %{}) do
    Repo.transaction(fn ->
      case create_work(attrs) do
        {:ok, work} -> work
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates a work.

  ## Examples

      iex> update_work(work, %{field: new_value})
      {:ok, %Work{}}

      iex> update_work(work, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_work(%Work{} = work, attrs) do
    work
    |> Work.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Adds a work to a collection

  ## Examples

      iex> add_to_collection(%Work{} = work, "01DYQWEW109B53VYG2M7B5TGFV")
      {:ok, %Meadow.Data.Schemas.Work{}}

      iex> add_to_collection(%Work{} = work, "bad_ulid")
      {:error, %Ecto.Changeset{}}

  """
  def add_to_collection(%Work{} = work, collection_id) do
    work
    |> Work.changeset(%{collection_id: collection_id})
    |> Repo.update()
  end

  @doc """
  Fetches all works that include a Metadata title.

  Returns [] if the query returns no matches

  ## Examples

      iex> get_works_by_title("Example record title")
      [%Work{},...]

      iex> get_work!("No title match")
      []

  """
  def get_works_by_title(title) do
    map = %{"title" => title}

    q =
      from Work,
        where: fragment("descriptive_metadata @> ?::jsonb", ^map)

    Repo.all(q)
  end

  @doc """
  Deletes a Work.
  """
  def delete_work(%Work{} = work) do
    Repo.delete(work)
  end
end
