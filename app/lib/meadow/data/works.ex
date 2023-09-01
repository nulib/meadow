defmodule Meadow.Data.Works do
  @moduledoc """
  The Works context.
  """
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.{FileSet, Work}
  alias Meadow.Repo

  use Meadow.Data.Works.BatchFunctions

  require Logger

  @doc """
  Returns the list of Works.

  ## Examples

      iex> list_works()
      [%Work{}, ...]

  """
  def list_works do
    Work
    |> preload([:ingest_sheet, :project])
    |> Repo.all()
    |> add_representative_image()
  end

  @doc """
  Returns a list of works matching the given `criteria`.

  Example Criteria:

  [{:limit, 15}, {:order, :asc}]}]
  """

  def list_works(criteria) do
    criteria
    |> work_query()
    |> preload([:ingest_sheet, :project])
    |> Repo.all()
    |> add_representative_image()
  end

  @doc """
  Returns a composable query matching the given `criteria`.
  """
  def work_query(criteria) do
    query = from(Work)

    Enum.reduce(criteria, query, fn
      {:collection, collection}, query ->
        from(w in query, where: w.collection_id == ^collection.id)

      {:collection_id, collection_id}, query ->
        from(w in query, where: w.collection_id == ^collection_id)

      {:limit, limit}, query ->
        from(w in query, limit: ^limit)

      {:filter, filters}, query ->
        filter_with(filters, query)

      {:order, order}, query ->
        from(p in query, order_by: [{^order, :id}])

      {:visibility, visibility}, query ->
        from(w in query, where: fragment("visibility -> 'id' = ?", ^visibility))

      {:work_type, work_type}, query ->
        from(w in query, where: fragment("work_type -> 'id' = ?", ^work_type))
    end)
  end

  defp filter_with(filters, query) do
    Enum.reduce(filters, query, fn
      {:matching, term}, query ->
        map = %{"title" => term}

        from(q in query,
          where: fragment("descriptive_metadata @> ?::jsonb", ^map)
        )
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
    |> preload([:ingest_sheet, :project])
    |> Repo.get!(id)
    |> add_representative_image()
  end

  def get_work(id) do
    Work
    |> preload([:ingest_sheet, :project])
    |> Repo.get(id)
    |> add_representative_image()
  end

  def get_works(id_list) do
    from(w in Work, where: w.id in ^id_list)
    |> Repo.all()
  end

  @doc """
  Gets a work by accession_number

  Raises `Ecto.NoResultsError` if the Work does not exist
  """
  def get_work_by_accession_number!(accession_number) do
    Work
    |> preload([:ingest_sheet, :project])
    |> Repo.get_by!(accession_number: accession_number)
    |> add_representative_image()
  end

  @doc """
  Gets a work by its ARK

  Raises `Ecto.NoResultsError` if the Work does not exist
  """

  def get_work_by_ark!(ark) do
    from(w in Work,
      where: fragment("?.descriptive_metadata->>'ark' = ?", w, ^ark),
      preload: [:ingest_sheet, :project, descriptive_metadata: :cached_ark]
    )
    |> Repo.one!()
    |> add_representative_image()
  end

  def get_access_files(work_id) do
    map = %{"id" => "A"}

    Repo.all(
      from(f in FileSet,
        where: f.work_id == ^work_id,
        where: fragment("role @> ?::jsonb", ^map),
        order_by: :rank,
        limit: 1
      )
    )
  end

  @doc """

  """
  def with_file_sets(id) do
    Work
    |> Repo.get!(id)
    |> Repo.preload([
      :ingest_sheet,
      :project,
      file_sets: from(FileSet, order_by: [asc: :role, asc: :rank])
    ])
    |> add_representative_image()
  end

  @doc """

  """
  def with_file_sets(id, role) do
    map = %{"id" => role}

    Work
    |> Repo.get!(id)
    |> Repo.preload([
      :ingest_sheet,
      :project,
      file_sets:
        from(f in FileSet,
          where: fragment("role @> ?::jsonb", ^map),
          order_by: [asc: :role, asc: :rank]
        )
    ])
    |> add_representative_image()
  end

  @doc """
  Gets a work with Ingest Sheet preloaded

  Raises `Ecto.NoResultsError` if the Work does not exist
  """
  def with_sheet(id) do
    Work
    |> preload(:ingest_sheet)
    |> Repo.get!(id)
    |> add_representative_image()
  end

  @doc """
  Check if accession number already exists in system

  iex> accession_exists?("123")
  true
  """
  def accession_exists?(accession_number) do
    Repo.exists?(from(w in Work, where: w.accession_number == ^accession_number))
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
  def ensure_create_work(attrs), do: ensure_create_work(attrs, & &1)

  def ensure_create_work(attrs, on_complete) do
    Repo.transaction(
      fn ->
        case create_work(attrs) do
          {:ok, work} -> work
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end,
      timeout: :infinity
    )
    |> after_ensure_create_work(on_complete)
  end

  defp after_ensure_create_work({:ok, work}, on_complete), do: {:ok, on_complete.(work)}
  defp after_ensure_create_work(result, _), do: result

  def create_work_all_fields(attrs \\ %{}) do
    case %Work{} |> Work.changeset(attrs) |> Repo.insert() do
      {:ok, work} -> set_default_representative_image(work)
      other -> other
    end
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

  def update_work!(%Work{} = work, attrs) do
    work
    |> Work.update_changeset(attrs)
    |> Repo.update!()
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
  Fetches all works for a given collection ID.

  Returns [] if the query returns no matches

  ## Examples

      iex> get_works_by_collection("db36d92c-dc17-417b-b662-f8c9e112de31")
      [%Work{},...]

      iex> get_work!("db36d92c-dc17-417b-b662-f8c9e112de32")
      []

  """
  def get_works_by_collection(collection_id) do
    from(w in Work, where: w.collection_id == ^collection_id)
    |> Repo.all()
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
  "https://prefix.dev.rdc.library.northwestern.edu:3002/works/bbd380c8-67d7-4b2b-aa90-e9f48faf6893?as=iiif"
  """
  def iiif_manifest_url(work_id) do
    api_url = Application.get_env(:meadow, :dc_api) |> get_in([:v2, "base_url"])
    "#{api_url}/works/#{work_id}?as=iiif"
  end

  @doc """
  Sets the representative_file_set_id for a work based
  on a file set

  ## Examples

      iex> set_representative_image(work, file_set)
      {:ok, %Work{}}
  """
  def set_representative_image(
        %Work{work_type: %{id: "VIDEO"}} = work,
        %FileSet{id: _id, role: %{id: "A"}, derivatives: %{"poster" => _poster}} = file_set
      ) do
    work
    |> Repo.preload(:representative_file_set)
    |> Work.update_changeset()
    |> put_assoc(:representative_file_set, file_set)
    |> Repo.update()
    |> add_representative_image()
  end

  def set_representative_image(%Work{work_type: %{id: "VIDEO"}} = work, %FileSet{
        id: _id,
        role: %{id: "A"}
      }),
      do: {:ok, work}

  def set_representative_image(%Work{} = work, file_set_id) when is_binary(file_set_id) do
    set_representative_image(work, FileSets.get_file_set!(file_set_id))
  end

  def set_representative_image(%Work{} = work, %FileSet{id: _id} = file_set) do
    work
    |> Repo.preload(:representative_file_set)
    |> Work.update_changeset()
    |> put_assoc(:representative_file_set, file_set)
    |> Repo.update()
    |> add_representative_image()
  end

  def set_representative_image(%Work{} = work, nil) do
    work
    |> Repo.preload(:representative_file_set)
    |> Work.update_changeset()
    |> put_assoc(:representative_file_set, nil)
    |> Repo.update()
    |> add_representative_image()
  end

  def set_representative_image!(work, file_set) do
    case set_representative_image(work, file_set) do
      {:ok, work} -> work
      {:error, err} -> raise err
    end
  end

  @doc """
  Sets the default representative_file_set_id for a work.
  For an image work, that's the first file set
  For an audio or video type work, default is nil

  ## Examples

      iex> set_default_representative_image(work)
      {:ok, %Work{}}
  """

  def set_default_representative_image(
        %Work{work_type: %{id: "AUDIO", scheme: "work_type"}} = work
      ),
      do: {:ok, work}

  def set_default_representative_image(
        %Work{work_type: %{id: "VIDEO", scheme: "work_type"}} = work
      ),
      do: {:ok, work}

  def set_default_representative_image(%Work{} = work) do
    work
    |> set_representative_image(get_access_files(work.id) |> List.first())
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
    work =
      if Ecto.assoc_loaded?(work.representative_file_set),
        do: work,
        else: work |> Repo.preload(:representative_file_set)

    case work.representative_file_set do
      nil ->
        Map.put(work, :representative_image, placeholder_url(work))

      file_set ->
        work
        |> Map.put(:representative_image, FileSets.representative_image_url_for(file_set))
    end
  end

  def add_representative_image(%Stream{} = stream),
    do: Stream.map(stream, &add_representative_image/1)

  def add_representative_image(works) when is_list(works),
    do: Enum.map(works, &add_representative_image/1)

  def add_representative_image({:ok, object}),
    do: {:ok, add_representative_image(object)}

  def add_representative_image(x), do: x

  defp placeholder_url(%Work{work_type: %{id: id}}) when id in ["AUDIO", "VIDEO"],
    do:
      FileSets.representative_image_url_for(%FileSet{
        derivatives: %{"pyramid_tiff" => nil},
        id: "00000000-0000-0000-0000-000000000002"
      })

  defp placeholder_url(_),
    do:
      FileSets.representative_image_url_for(%FileSet{
        derivatives: %{"pyramid_tiff" => nil},
        id: "00000000-0000-0000-0000-000000000001"
      })

  @doc """
  Set :updated_at
  """
  def merge_updated_at(query) do
    from(query,
      update: [
        set: [
          {:updated_at, ^DateTime.utc_now()}
        ]
      ]
    )
  end

  @doc """
  Update the order of the file sets attached to a work
  """
  def update_file_set_order(work_id, role_id, ordered_file_set_ids) do
    ensure_file_set_list_unique(ordered_file_set_ids)
    |> ensure_file_set_list_complete(work_id, role_id, ordered_file_set_ids)
    |> reorder_file_sets(ordered_file_set_ids)
  end

  defp ensure_file_set_list_unique(file_set_ids) do
    if Enum.uniq(file_set_ids) == file_set_ids,
      do: :ok,
      else: {:error, "FileSet IDs must be a unique list"}
  end

  defp ensure_file_set_list_complete({:error, msg}, _, _, _), do: {:error, msg}

  defp ensure_file_set_list_complete(:ok, work_id, role_id, file_set_ids) do
    map = %{"id" => role_id}

    work =
      from(w in Work,
        join: f in assoc(w, :file_sets),
        where: w.id == ^work_id,
        where: fragment("role @> ?::jsonb", ^map),
        preload: [file_sets: f]
      )
      |> Repo.one()

    work_file_set_ids = Enum.map(work.file_sets, &Map.get(&1, :id))
    missing_file_set_ids = work_file_set_ids -- file_set_ids
    extra_file_set_ids = file_set_ids -- work_file_set_ids

    cond do
      length(missing_file_set_ids) > 0 ->
        {:error, "Ordered file set list is missing #{inspect(missing_file_set_ids)}"}

      length(extra_file_set_ids) > 0 ->
        {:error, "Extra file set IDs provided: #{inspect(extra_file_set_ids)}"}

      true ->
        {:ok, work}
    end
  end

  defp reorder_file_sets({:error, msg}, _), do: {:error, msg}

  defp reorder_file_sets({:ok, work}, ordered_ids) do
    work.file_sets
    |> Enum.sort_by(&Enum.find_index(ordered_ids, fn id -> &1.id == id end))
    |> Enum.with_index(1)
    |> Enum.reduce(Multi.new(), fn {file_set, index}, multi ->
      Multi.update(multi, :"index_#{index}", FileSet.changeset(file_set, %{position: index}))
    end)
    |> Multi.update(:work, work |> Work.update_timestamp())
    |> Repo.transaction()
  end

  def verify_file_sets(work_id) do
    work_id
    |> with_file_sets()
    |> Map.get(:file_sets)
    |> Enum.map(fn file_set ->
      %{file_set_id: file_set.id, verified: verify_file_set(file_set)}
    end)
  end

  defp verify_file_set(file_set) do
    case ExAws.S3.head_object(
           Config.preservation_bucket(),
           URI.parse(file_set.core_metadata.location).path
         )
         |> ExAws.request() do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
end
