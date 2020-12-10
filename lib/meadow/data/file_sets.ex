defmodule Meadow.Data.FileSets do
  @moduledoc """
  The FileSets context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Repo

  @doc """
  Returns the list of FileSets.

  ## Examples

      iex> list_file_sets()
      [%FileSet{}, ...]

  """
  def list_file_sets do
    Repo.all(FileSet)
  end

  @doc """
  Gets a file set.

  Raises `Ecto.NoResultsError` if the FileSet does not exist.

  ## Examples

      iex> get_file_set!("123")
      %FileSet{}

      iex> get_file_set!("456")
      ** (Ecto.NoResultsError)

  """
  def get_file_set!(id), do: Repo.get!(FileSet, id)

  @doc """
  Gets a file_set by accession_number

  Raises `Ecto.NoResultsError` if the Work does not exist
  """
  def get_file_set_by_accession_number!(accession_number) do
    Repo.get_by!(FileSet, accession_number: accession_number)
  end

  @doc """
  Gets a file_set with its work and ingest_sheet preloaded

  Raises `Ecto.NoResultsError` if the FileSet does not exist.

  ## Examples

      iex> get_file_set_with_work_and_sheet!("123")
      %FileSet{}

      iex> get_file_set_with_work_and_sheet!("456")
      ** (Ecto.NoResultsError)
  """
  def get_file_set_with_work_and_sheet!(id) do
    FileSet
    |> preload(work: [:ingest_sheet])
    |> Repo.get!(id)
  end

  @doc """
  Check if accession number already exists in system

  iex> accession_exists?("123")
  true
  """
  def accession_exists?(accession_number) do
    Repo.exists?(from f in FileSet, where: f.accession_number == ^accession_number)
  end

  @doc """
  Creates a file set.

  ## Examples

      iex> create_file_set(%{field: value})
      {:ok, %Meadow.Data.Schemas.FileSet{}}

      iex> create_work(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_file_set(attrs \\ %{}) do
    %FileSet{}
    |> FileSet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a FileSet.
  """
  def delete_file_set(%FileSet{} = file_set) do
    Repo.delete(file_set)
  end

  @doc """
  Updates a FileSet.
  """
  def update_file_set(%FileSet{} = file_set, attrs) do
    file_set
    |> FileSet.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Dynamically compute the position for each item in a list of maps
  that include the key `:position`.

  ## Examples

      iex> compute_positions([%{position: nil}, %{position: nil}])
      [%{position: 0}, %{position: 1}]

  """
  def compute_positions(ordered_items \\ []) do
    for {item, i} <- Enum.with_index(ordered_items) do
      %{item | position: i}
    end
  end
end
