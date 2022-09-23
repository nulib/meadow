defmodule Meadow.Batches do
  @moduledoc """
  Meadow batch context
  """

  import Ecto.Query, warn: false
  alias Meadow.Data.{Indexer, Works}
  alias Meadow.Data.Schemas.{Batch, Work}
  alias Meadow.Repo
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.HTTP

  require Logger

  @batch_index SearchConfig.alias_for(Work, 1)
  @controlled_fields ~w(contributor creator genre language location style_period subject technique)a

  @doc """
  Creates a batch.

  ## Examples

      iex> create_batch(%{field: value})
      {:ok, %Meadow.Schemas.Batch{}}

      iex> create_batch(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_batch(attrs \\ %{}) do
    %Batch{}
    |> Batch.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Same as create_batch/1 but raises on error
  """
  def create_batch!(attrs \\ %{}) do
    %Batch{}
    |> Batch.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Updates a Batch.
  """
  def update_batch(%Batch{} = batch, attrs) do
    batch
    |> Batch.changeset(attrs)
    |> Repo.update()
  end

  def update_batch(batch_id, attrs) do
    batch = Repo.get!(Batch, batch_id)
    update_batch(batch, attrs)
  end

  @doc """
  Same as update_batch(%Batch{} = batch, attrs) but raises an error
  """
  def update_batch!(%Batch{} = batch, attrs) do
    batch
    |> Batch.changeset(attrs)
    |> Repo.update!()
  end

  @doc """
  Returns a list of Batches.

  ## Examples

      iex> list_batches()
      [%Batch{}, ...]

  """
  def list_batches do
    Repo.all(Batch)
  end

  @doc """
  Returns a list of batches matching the given `criteria`.

  Example Criteria:

  [{:limit, 15}, {:order, :asc}]}]
  """

  def list_batches(criteria) do
    query = from(Batch)

    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from(b in query, limit: ^limit)

      {:order, order}, query ->
        from(b in query, order_by: [{^order, :id}])
    end)
    |> Repo.all()
  end

  @doc """
  Gets a batch.

  Raises `Ecto.NoResultsError` if the Batch does not exist.

  ## Examples

      iex> get_batch!("123")
      %Batch{}

      iex> get_batch!("456")
      ** (Ecto.NoResultsError)

  """
  def get_batch!(id) do
    Batch
    |> Repo.get!(id)
  end

  def process_batch(%Batch{type: "update"} = batch) do
    perform_batch(batch)
  end

  def process_batch(%Batch{type: "delete"} = batch) do
    perform_batch(batch)
  end

  def process_batch(%Batch{type: mode}) do
    {:error, "mode: #{mode} not implemented"}
  end

  defp perform_batch(batch) do
    case set_active(batch) do
      {:ok, batch} ->
        log_batch_info(batch)

        try do
          case do_update(batch) do
            {:ok, _any} ->
              Logger.info("Batch #{batch.id} complete")
              {:ok, set_complete!(batch)}

            {:error, any} ->
              Logger.info("Batch #{batch.id} transaction error: #{inspect(any)}")

              {:error,
               set_error!(batch, "An error occured during the transaction: #{inspect(any)}")}
          end
        rescue
          e ->
            Logger.error("Rescued error for batch #{batch.id}: #{Exception.message(e)}")
            Logger.error(Exception.format(:error, e, __STACKTRACE__))
            {:error, set_error!(batch, Exception.message(e))}
        end

      {:error, %Ecto.Changeset{}} ->
        Logger.info("Couldn't start batch #{batch.id}. Active batch already exists.")
        {:ok, batch}
    end
  end

  defp do_update(%Batch{type: "update"} = batch) do
    Meadow.Repo.transaction(
      fn ->
        process_updates(
          batch.query,
          decode_value(batch.delete),
          decode_value(batch.add),
          decode_value(batch.replace),
          batch.id
        )

        Indexer.synchronize_index()
      end,
      timeout: :infinity
    )
  end

  defp do_update(%Batch{type: "delete"} = batch) do
    Meadow.Repo.transaction(
      fn ->
        process_deletes(
          batch.query,
          batch.id
        )

        Indexer.synchronize_index()
      end,
      timeout: :infinity
    )
  end

  defp set_active(batch) do
    update_batch(batch, %{
      started: DateTime.utc_now(),
      status: "in_progress",
      active: true
    })
  end

  defp set_complete!(batch) do
    update_batch!(batch, %{
      status: "complete",
      active: false
    })
  end

  defp set_error!(batch, message) do
    update_batch!(batch, %{
      status: "error",
      active: false,
      error: message
    })
  end

  @doc """
  Returns the next batch in queue, if there is one
  """
  def next_batch do
    Repo.one(
      from(b in Batch, where: b.status == "queued", order_by: [asc: b.inserted_at], limit: 1)
    )
  end

  @doc """
  Finds stalled active batches and sets them to error state
  """
  def purge_stalled(seconds) do
    {count, _} =
      stalled(seconds)
      |> Repo.update_all(
        set: [
          active: "false",
          status: "error",
          error: "Batch timed out",
          works_updated: 0,
          updated_at: DateTime.utc_now()
        ]
      )

    {:ok, count}
  end

  defp stalled(seconds) do
    timeout = DateTime.utc_now() |> DateTime.add(-seconds, :second)

    from(b in Batch,
      where:
        b.active == true and
          b.started <= ^timeout
    )
  end

  # Apply sets of controlled field deletes/adds to a batch of works

  defp apply_controlled_field_changes([], _delete, _add), do: []

  defp apply_controlled_field_changes(work_ids, delete, nil),
    do: apply_controlled_field_changes(work_ids, delete, %{descriptive_metadata: %{}})

  defp apply_controlled_field_changes(work_ids, delete, add) do
    @controlled_fields
    |> Enum.each(fn field ->
      apply_controlled_field_changes(
        work_ids,
        field,
        get_in(delete, [field]),
        get_in(add, [:descriptive_metadata, field])
      )
    end)

    work_ids
  end

  defp apply_controlled_field_changes(work_ids, _field, nil, nil), do: work_ids
  defp apply_controlled_field_changes(work_ids, _field, [], nil), do: work_ids
  defp apply_controlled_field_changes(work_ids, _field, nil, []), do: work_ids
  defp apply_controlled_field_changes(work_ids, _field, [], []), do: work_ids

  defp apply_controlled_field_changes(work_ids, field, delete, add) do
    delete = prepare_controlled_field_list(delete)
    add = prepare_controlled_field_list(add)

    Logger.debug("Batch updating controlled fields")

    from(w in Work, where: w.id in ^work_ids)
    |> Works.replace_controlled_value(
      :descriptive_metadata,
      to_string(field),
      delete,
      add
    )
    |> Repo.update_all([])

    work_ids
  end

  # Make sure all controlled field lists are lists, and that each value has a role

  defp prepare_controlled_field_list(nil), do: []

  defp prepare_controlled_field_list(data) when is_list(data),
    do: Enum.map(data, fn entry -> Map.put(entry, :role, Map.get(entry, :role, nil)) end)

  defp prepare_controlled_field_list(data), do: prepare_controlled_field_list([data])

  # Apply sets of controlled field adds/replacements to a batch of works

  defp apply_uncontrolled_field_changes([], _add, _replace), do: []

  defp apply_uncontrolled_field_changes(work_ids, add, replace) do
    add = if is_nil(add), do: %{}, else: add
    replace = if is_nil(replace), do: %{}, else: replace

    visibility = Map.get(replace, :visibility, :not_present)
    published = Map.get(replace, :published, :not_present)
    reading_room = Map.get(replace, :reading_room, :not_present)

    with collection_id <- add |> Map.merge(replace) |> Map.get(:collection_id, :not_present) do
      update_collection(work_ids, collection_id)
      |> update_top_level_field(:visibility, visibility)
      |> update_top_level_field(:published, published)
      |> update_top_level_field(:reading_room, reading_room)
      |> merge_uncontrolled_fields(add, :append)
      |> merge_uncontrolled_fields(replace, :replace)
    end
  end

  defp merge_uncontrolled_fields(work_ids, new_values, _mode)
       when map_size(new_values) == 0,
       do: work_ids

  defp merge_uncontrolled_fields(work_ids, new_values, mode) do
    mergeable_descriptive_metadata =
      new_values
      |> Map.get(:descriptive_metadata, %{})
      |> Enum.filter(fn {key, _} -> key not in @controlled_fields end)
      |> Enum.into(%{})
      |> humanize_date_created()

    mergeable_administrative_metadata =
      new_values
      |> Map.get(:administrative_metadata, %{})
      |> Enum.into(%{})

    if map_size(mergeable_descriptive_metadata) + map_size(mergeable_administrative_metadata) > 0 do
      from(w in Work, where: w.id in ^work_ids)
      |> Works.merge_metadata_values(:descriptive_metadata, mergeable_descriptive_metadata, mode)
      |> Works.merge_metadata_values(
        :administrative_metadata,
        mergeable_administrative_metadata,
        mode
      )
      |> Works.merge_updated_at()
      |> Repo.update_all([])
    end

    work_ids
  end

  defp humanize_date_created(%{date_created: date_created} = descriptive_metadata) do
    new_dates =
      Enum.map(date_created, fn d ->
        edtf = Map.get(d, :edtf)

        case EDTF.humanize(edtf) do
          {:error, error} ->
            raise error

          result ->
            %{edtf: edtf, humanized: result}
        end
      end)

    Map.replace!(descriptive_metadata, :date_created, new_dates)
  end

  defp humanize_date_created(descriptive_metadata), do: descriptive_metadata

  defp update_top_level_field(work_ids, _field, :not_present), do: work_ids

  defp update_top_level_field(work_ids, field, value) do
    Logger.debug("Batch updating #{field}")

    update_args = Keyword.new([{field, value}, {:updated_at, DateTime.utc_now()}])

    from(
      w in Work,
      update: [set: ^update_args],
      where: w.id in ^work_ids
    )
    |> Repo.update_all([])

    work_ids
  end

  defp update_collection(work_ids, :not_present), do: work_ids

  defp update_collection(work_ids, value) do
    Logger.debug("Batch updating collection_id: #{value}")

    from(w in Work, where: w.id in ^work_ids)
    |> Repo.update_all(
      set: [
        collection_id: value,
        updated_at: DateTime.utc_now()
      ]
    )

    work_ids
  end

  defp apply_batch_association(work_ids, batch_id) do
    Logger.debug("Associating batch_id: #{batch_id} with works")
    {:ok, b_id} = Ecto.UUID.dump(batch_id)

    entries =
      Enum.map(work_ids, fn work_id ->
        with {:ok, w_id} <- Ecto.UUID.dump(work_id) do
          %{
            batch_id: b_id,
            work_id: w_id,
            inserted_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now()
          }
        end
      end)

    Repo.insert_all("works_batches", entries, on_conflict: :nothing)
    work_ids
  end

  defp validate_work_ids(work_ids) do
    from(w in Work, where: w.id in ^work_ids, select: w.id) |> Repo.all()
  end

  # Scroll over the search results and apply changes to each page of work IDs.

  defp process_updates(
         %{"hits" => %{"hits" => []}},
         _delete,
         _add,
         _replace,
         batch_id
       ) do
    with {:ok, batch_uuid} <- Ecto.UUID.dump(batch_id),
         total <-
           from(wb in "works_batches", where: wb.batch_id == ^batch_uuid)
           |> Repo.aggregate(:count) do
      update_batch(batch_id, %{works_updated: total})
    end

    {:ok, :noop}
  end

  defp process_updates(
         %{"_scroll_id" => scroll_id, "hits" => hits},
         delete,
         add,
         replace,
         batch_id
       ) do
    current_hits = Map.get(hits, "hits")

    current_hits
    |> Enum.map(&Map.get(&1, "_id"))
    |> validate_work_ids()
    |> apply_controlled_field_changes(delete, add)
    |> apply_uncontrolled_field_changes(add, replace)
    |> apply_batch_association(batch_id)
    |> load_works()

    total = get_in(hits, ["total", "value"])

    Logger.debug(
      "Indexing for batch update scroll_id: #{scroll_id}, hits: #{length(current_hits)}, total: #{total}"
    )

    HTTP.post!("/_search/scroll", %{scroll: "1m", scroll_id: scroll_id})
    |> Map.get(:body)
    |> process_updates(delete, add, replace, batch_id)
  end

  defp process_updates(query, delete, add, replace, batch_id) do
    query =
      query
      |> Jason.decode!()
      |> Map.put("_source", "")
      |> Jason.encode!()

    Logger.debug("Starting Elasticsearch scroll for batch update")
    Logger.debug("query #{inspect(query)}")

    HTTP.post!([@batch_index, "_search?scroll=10m"], query)
    |> Map.get(:body)
    |> process_updates(delete, add, replace, batch_id)
  end

  # Iterate over the Elasticsearch scroll and apply changes to each page of work IDs.

  defp process_deletes(
         %{"hits" => %{"hits" => [], "total" => %{"value" => total}}},
         batch_id
       ) do
    update_batch(batch_id, %{works_updated: total})
    {:ok, :noop}
  end

  defp process_deletes(%{"_scroll_id" => scroll_id, "hits" => hits}, batch_id) do
    current_hits = Map.get(hits, "hits")

    current_hits
    |> Enum.map(&Map.get(&1, "_id"))
    |> delete_works()

    HTTP.post!("/_search/scroll", %{scroll: "1m", scroll_id: scroll_id})
    |> Map.get(:body)
    |> process_deletes(batch_id)
  end

  defp process_deletes(query, batch_id) do
    query =
      Jason.decode!(query)
      |> Map.put("_source", "")
      |> Jason.encode!()

    Logger.debug("Starting Elasticsearch scroll for batch delete")
    Logger.debug("query #{inspect(query)}")

    HTTP.post!([@batch_index, "_search?scroll=10m"], query)
    |> Map.get(:body)
    |> process_deletes(batch_id)
  end

  defp delete_works(work_ids) do
    from(w in Work, where: w.id in ^work_ids)
    |> Repo.delete_all()
  end

  defp load_works(work_ids) do
    from(w in Work, where: w.id in ^work_ids)
    |> Repo.all()
  end

  defp decode_value(nil), do: nil

  defp decode_value(json_string) do
    Jason.decode!(json_string, keys: :atoms)
  end

  defp log_batch_info(batch) do
    Logger.info("Processing batch #{batch.type} for batch_id: #{batch.id}")
    Logger.debug("query: #{batch.query}")
    Logger.debug("delete: #{inspect(batch.delete)}")
    Logger.debug("add: #{inspect(batch.add)}")
    Logger.debug("replace: #{inspect(batch.replace)}")
  end
end
