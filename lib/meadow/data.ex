defmodule Meadow.Data do
  @moduledoc """
  The Data context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.FileSets.FileSet
  alias Meadow.Repo

  @doc """
  Fetches a work by file_set id.

  Raises `Ecto.NoResultsError` if the FileSet does not exist.

  ## Examples

      iex> get_work_by_file_set_id("2ff9a2b3-b563-4840-9bc0-5d8b5aeb")
      %Meadow.Data.Works.Work{}

      iex> get_work_by_file_set_id("1234")
      ** (Ecto.NoResultsError)

  """
  def get_work_by_file_set_id(id) do
    Repo.get!(FileSet, id)
    |> Ecto.assoc(:work)
    |> Repo.one()
  end

  # Dataloader

  def datasource do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(queryable, _) do
    queryable
  end
end
