defmodule Meadow.Data.FileSets do
  @moduledoc """
  The FileSets context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Meadow.Config
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Repo
  alias Meadow.Utils.Pairtree

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

  """
  def get_file_set(id), do: Repo.get(FileSet, id)

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
  Processes metadata updates for an array of file sets.

  ## Examples

      iex> update_file_sets(%{id: "2b281f5f-bbca-4bfb-a323-df1ab595e99f", core_metadata: %{label: "new label", description: "new description"}})
      {:ok, [%Meadow.Data.Schemas.FileSet{}]}

      iex> update_file_sets(%{id: "2b281f5f-bbca-4bfb-a323-df1ab595e99f", core_metadata: %{label: 009, description: "new description"}})
      {:error, :file_set_1, %Ecto.Changeset{}}
  """
  def update_file_sets(file_set_updates) do
    case multi_update(file_set_updates) do
      {:ok, file_sets} ->
        {:ok, Enum.map(file_sets, fn {_index, fs} -> fs end)}

      {:error, index, changeset, _} ->
        {:error, index, changeset}
    end
  end

  def add_derivative(%FileSet{derivatives: nil}, type, value),
    do: add_derivative_to_map(%{}, type, value)

  def add_derivative(%FileSet{derivatives: map}, type, value),
    do: add_derivative_to_map(map, type, value)

  defp add_derivative_to_map(map, type, value), do: Map.put(map, to_string(type), value)

  defp multi_update(file_set_updates) do
    file_set_updates
    |> Enum.with_index(1)
    |> Enum.reduce(Multi.new(), fn {changes, index}, multi ->
      Multi.update(
        multi,
        :"index_#{index}",
        FileSet.update_changeset(get_file_set!(changes.id), %{
          core_metadata: Map.get(changes, :core_metadata, %{}),
          structural_metadata: Map.get(changes, :structural_metadata, %{}),
          updated_at: NaiveDateTime.utc_now()
        })
      )
    end)
    |> Repo.transaction()
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

  @doc """
  Get the pyramid path for a file set
  """
  def pyramid_uri_for(%FileSet{role: %{id: "P"}}), do: nil
  def pyramid_uri_for(%FileSet{} = file_set), do: pyramid_uri_for(file_set.id)

  def pyramid_uri_for(file_set_id) do
    dest_bucket = Config.pyramid_bucket()

    dest_key = Path.join(["/", Pairtree.pyramid_path(file_set_id)])

    %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()
  end

  @doc """
  Get the distribution streaming playlist url for a file set
  """
  def distribution_streaming_uri_for(%FileSet{derivatives: %{"playlist" => playlist}}) do
    with %{path: path} <- URI.parse(playlist) do
      %URI{
        scheme: "https",
        host: Config.streaming_host(),
        path: path
      }
      |> URI.to_string()
    end
  end

  def distribution_streaming_uri_for(_), do: nil

  @doc """
  Get the streaming path for a file set
  """
  def streaming_uri_for(%FileSet{role: %{id: "P"}}), do: nil
  def streaming_uri_for(%FileSet{} = file_set), do: streaming_uri_for(file_set.id)

  def streaming_uri_for(file_set_id) do
    bucket = Config.streaming_bucket()
    key = "/" <> Pairtree.generate!(file_set_id) <> "/"
    %URI{scheme: "s3", host: bucket, path: key} |> URI.to_string()
  end
end
