defmodule Meadow.Data.Works do
  @moduledoc """
  The Works context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Config
  alias Meadow.Data.Schemas.{FileSet, Work}
  alias Meadow.Ingest.Sheets
  alias Meadow.Repo
  alias Meadow.Utils.Pairtree

  @doc """
  Returns the list of Works.

  ## Examples

      iex> list_works()
      [%Work{}, ...]

  """
  def list_works do
    Work
    |> Sheets.works_with_sheets()
    |> Repo.all()
    |> add_representative_image()
  end

  @doc """
  Returns a list of works matching the given `criteria`.

  Example Criteria:

  [{:limit, 15}, {:order, :asc}, {:filter, [{:visibility, :open}, {:work_type, :image}]}]
  """

  def list_works(criteria) do
    query = from(Work)

    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from w in query, limit: ^limit

      {:filter, filters}, query ->
        filter_with(filters, query)

      {:order, order}, query ->
        from p in query, order_by: [{^order, :id}]
    end)
    |> Sheets.works_with_sheets()
    |> Repo.all()
    |> add_representative_image()
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
  def get_work!(id) do
    Work
    |> Sheets.works_with_sheets()
    |> Repo.get!(id)
    |> add_representative_image()
  end

  @doc """
  Gets a work by accession_number

  Raises `Ecto.NoResultsError` if the Work does not exist
  """
  def get_work_by_accession_number!(accession_number) do
    Work
    |> Sheets.works_with_sheets()
    |> Repo.get_by!(accession_number: accession_number)
    |> add_representative_image()
  end

  @doc """

  """
  def with_file_sets(id) do
    Work
    |> Sheets.works_with_sheets()
    |> where([work], work.id == ^id)
    |> preload(:file_sets)
    |> Repo.one()
    |> add_representative_image()
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
    case %Work{} |> Work.changeset(attrs) |> Repo.insert() do
      {:ok, work} -> set_default_representative_image(work)
      other -> other
    end
  end

  @doc """
  Same as create_work/1 but raises on error
  """
  def create_work!(attrs \\ %{}) do
    %Work{}
    |> Work.changeset(attrs)
    |> Repo.insert!()
    |> set_default_representative_image!()
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
    |> Work.update_changeset(attrs)
    |> Repo.update()
    |> add_representative_image()
  end

  @doc """
  Adds a work to a collection

  ## Examples

      iex> add_to_collection(%Work{} = work, "01DYQWEW109B53VYG2M7B5TGFV")
      {:ok, %Meadow.Data.Schemas.Work{}}

      iex> add_to_collection(%Work{} = work, "bad_uuid")
      {:error, %Ecto.Changeset{}}

  """
  def add_to_collection(%Work{} = work, collection_id) do
    work
    |> Work.update_changeset(%{collection_id: collection_id})
    |> Repo.update()
    |> add_representative_image()
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

    from(Work,
      where: fragment("descriptive_metadata @> ?::jsonb", ^map)
    )
    |> Repo.all()
    |> add_representative_image()
  end

  @doc """
  Deletes a Work.
  """
  def delete_work(%Work{} = work) do
    Repo.delete(work)
  end

  @doc """
  Retrieves the IIIF Manifest URL for a work
  iex> iiif_manifest_url("f352eb30-ae2f-4b49-81f9-6eb4659a3f47")
  "https://iiif.stack.rdc.library.northwestern.edu/public/f3/52/eb/30/-a/e2/f-/4b/49/-8/1f/9-/6e/b4/65/9a/3f/47-manifest.json"

  iex> iiif_manifest_url(%Work{id:"f352eb30-ae2f-4b49-81f9-6eb4659a3f47"})
  "https://iiif.stack.rdc.library.northwestern.edu/public/f3/52/eb/30/-a/e2/f-/4b/49/-8/1f/9-/6e/b4/65/9a/3f/47-manifest.json"

  """
  def iiif_manifest_url(%Work{id: id}) do
    iiif_manifest_url(id)
  end

  def iiif_manifest_url(work_id) do
    Config.iiif_manifest_url() <> Pairtree.manifest_path(work_id)
  end

  @doc """
  Sets the representative_file_set_id for a work based
  on a file set

  ## Examples

      iex> set_representative_image(work, file_set)
      {:ok, %Work{}}
  """
  def set_representative_image(%Work{} = work, %FileSet{id: id}) do
    work
    |> update_work(%{representative_file_set_id: id})
  end

  def set_representative_image(%Work{} = work, nil) do
    work
    |> update_work(%{representative_file_set_id: nil})
  end

  @doc """
  Sets the default representative_file_set_id for a work

  ## Examples

      iex> set_default_representative_image(work)
      {:ok, %Work{}}
  """
  def set_default_representative_image(%Work{} = work) do
    work =
      if Ecto.assoc_loaded?(work.file_sets),
        do: work,
        else: work |> Repo.preload(file_sets: from(FileSet, order_by: :rank, limit: 1))

    work
    |> set_representative_image(work.file_sets |> List.first())
  end

  @doc """
  Sets the default representative_file_set_id for a work

  ## Examples

      iex> set_default_representative_image!(work)
      %Work{}
  """
  def set_default_representative_image!(%Work{} = work) do
    case set_default_representative_image(work) do
      {:ok, work} -> work
      {:error, err} -> raise err
    end
  end

  @doc """
  Sets the value of the representative_image virtual field
  for a work, list of works, or stream of works
  """
  def add_representative_image(%Work{} = work) do
    case work.representative_file_set_id do
      nil -> Map.put(work, :representative_image, nil)
      id -> Map.put(work, :representative_image, representative_image_url(id))
    end
  end

  def add_representative_image(%Stream{} = stream),
    do: Stream.map(stream, &add_representative_image/1)

  def add_representative_image(works) when is_list(works),
    do: Enum.map(works, &add_representative_image/1)

  def add_representative_image({:ok, object}),
    do: {:ok, add_representative_image(object)}

  def add_representative_image(x), do: x

  defp representative_image_url(nil), do: nil

  defp representative_image_url(id) do
    with uri <- URI.parse(Meadow.Config.iiif_server_url()) do
      uri
      |> URI.merge(id)
      |> URI.to_string()
    end
  end
end
