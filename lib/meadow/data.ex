defmodule Meadow.Data do
  @moduledoc """
  The Data context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Repo

  @doc """
  Fetches a work by file_set id.

  Raises `Ecto.NoResultsError` if the FileSet does not exist.

  ## Examples

      iex> get_work_by_file_set_id("2ff9a2b3-b563-4840-9bc0-5d8b5aeb")
      %Meadow.Data.Schemas.Work{}

      iex> get_work_by_file_set_id("1234")
      ** (Ecto.NoResultsError)

  """
  def get_work_by_file_set_id(id) do
    Repo.get!(FileSet, id)
    |> Ecto.assoc(:work)
    |> Repo.one()
  end

  @doc """
  Query returning a list of FileSets for a Work ordered by `:rank`.

  ## Examples

      iex> ranked_file_sets_for_work("01DT7V79D45B8BQMVS6YDRSF9J", "A")
      [%Meadow.Data.Schemas.FileSet{rank: -100}, %Meadow.Data.Schemas.FileSet{rank: 0}, %Meadow.Data.Schemas.FileSet{rank: 100}]

      iex> ranked_file_sets_for_work(Ecto.UUID.generate())
      []

  """
  def ranked_file_sets_for_work(work_id, role_id) do
    map = %{"id" => role_id}

    Repo.all(
      from f in FileSet,
        where: f.work_id == ^work_id,
        where: fragment("role @> ?::jsonb", ^map),
        order_by: :rank
    )
  end

  # Dataloader

  def datasource do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(queryable, _) do
    queryable
  end
end
