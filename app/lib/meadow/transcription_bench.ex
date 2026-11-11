defmodule Meadow.TranscriptionBench do
  @moduledoc """
  The transcription bench: try prompts, structured outputs and models on file sets'
  images, with the same image and the same Bedrock call as `Meadow.Data.Transcriber`,
  and keep each attempt to look at and compare.

  A run is every chosen file set x model x variant, capped at `max_transcriptions/0`
  so that a careless selection cannot multiply into a large bill.
  """

  import Ecto.Query

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.{FileSet, FileSetDerivative}
  alias Meadow.Repo
  alias Meadow.TranscriptionBench.{Parser, Result, Run}

  @max_transcriptions 10
  # A Bedrock stream times out after 15 minutes, and a queued result waits for at most
  # two rounds of them, so anything unfinished after this was lost with its node.
  @stale_after_minutes 45

  @doc "The most transcriptions one run may hold."
  def max_transcriptions, do: @max_transcriptions

  # ---------------------------------------------------------------------------
  # Transcribable file sets
  # ---------------------------------------------------------------------------

  @doc """
  A page of the file sets a transcription can be made of: access files with an image
  MIME type and a pyramid to fetch the image from.

  ## Options

    * `:limit` (default 10, at most 100) and `:offset`
    * `:collection_id` - only file sets of works in this collection
    * `:work` - only file sets of works with this id or accession number, or with this
      text in their title

  Returns `%{total: count, file_sets: [map]}`.
  """
  def list_transcribable_file_sets(opts \\ []) do
    limit = opts |> Keyword.get(:limit, 10) |> max(1) |> min(100)
    offset = opts |> Keyword.get(:offset, 0) |> max(0)

    query =
      transcribable()
      |> filter_collection(Keyword.get(opts, :collection_id))
      |> filter_work(Keyword.get(opts, :work))

    file_sets =
      query
      |> order_by([file_set: f, work: w], asc: w.accession_number, asc: f.rank, asc: f.id)
      |> limit(^limit)
      |> offset(^offset)
      |> select(
        [file_set: f, core: cm, work: w, descriptive: dm, collection: c],
        %{
          id: f.id,
          accession_number: f.accession_number,
          label: cm.label,
          original_filename: cm.original_filename,
          work_id: w.id,
          work_title: dm.title,
          work_accession_number: w.accession_number,
          collection_id: c.id,
          collection_title: c.title
        }
      )
      |> Repo.all()
      |> Enum.map(fn file_set ->
        file_set
        |> Map.put(:label, file_set.label || file_set.original_filename)
        |> Map.put(:representative_image_url, FileSets.iiif_image_url(file_set.id))
      end)

    %{total: Repo.aggregate(query, :count), file_sets: file_sets}
  end

  defp transcribable do
    from(f in FileSet,
      as: :file_set,
      join: cm in assoc(f, :core_metadata),
      as: :core,
      join: w in assoc(f, :work),
      as: :work,
      left_join: dm in assoc(w, :descriptive_metadata),
      as: :descriptive,
      left_join: c in assoc(w, :collection),
      as: :collection,
      where: f.role == "A",
      where: like(cm.mime_type, "image/%"),
      where:
        exists(
          from(d in FileSetDerivative,
            where: d.file_set_id == parent_as(:file_set).id and d.kind == "pyramid_tiff"
          )
        )
    )
  end

  defp filter_collection(query, id) when is_binary(id) and id != "" do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> where(query, [work: w], w.collection_id == ^uuid)
      :error -> where(query, [], false)
    end
  end

  defp filter_collection(query, _), do: query

  defp filter_work(query, work) when is_binary(work) do
    case String.trim(work) do
      "" ->
        query

      text ->
        pattern = "%" <> String.replace(text, ~r/[\\%_]/, "\\\\\\0") <> "%"

        case Ecto.UUID.cast(text) do
          {:ok, uuid} ->
            where(query, [work: w], w.id == ^uuid)

          :error ->
            where(
              query,
              [work: w, descriptive: dm],
              w.accession_number == ^text or ilike(dm.title, ^pattern)
            )
        end
    end
  end

  defp filter_work(query, _), do: query

  # ---------------------------------------------------------------------------
  # Runs
  # ---------------------------------------------------------------------------

  @doc "Runs, newest first, with their counts and without their results."
  def list_runs(opts \\ []) do
    expire_stale()

    runs =
      from(r in Run,
        order_by: [desc: r.inserted_at],
        limit: ^Keyword.get(opts, :limit, 50),
        offset: ^Keyword.get(opts, :offset, 0)
      )
      |> Repo.all()

    counts =
      from(t in Result,
        where: t.run_id in ^Enum.map(runs, & &1.id),
        group_by: [t.run_id, t.status],
        select: {t.run_id, t.status, count(t.id)}
      )
      |> Repo.all()
      |> Enum.group_by(&elem(&1, 0), fn {_, status, count} -> {status, count} end)

    Enum.map(runs, &with_counts(&1, Map.new(Map.get(counts, &1.id, []))))
  end

  @doc "A run with its results, each read by `Meadow.TranscriptionBench.Parser`."
  def get_run(id) do
    expire_stale()

    with {:ok, uuid} <- Ecto.UUID.cast(id),
         %Run{} = run <- Run |> Repo.get(uuid) |> Repo.preload(:results) do
      variants = Map.new(run.variants, &{&1["id"], &1})
      results = Enum.map(run.results, &parse(&1, Map.get(variants, &1.variant_id)))
      with_counts(%{run | results: results}, Enum.frequencies_by(results, & &1.status))
    else
      _ -> nil
    end
  end

  defp with_counts(run, counts) do
    count = &Map.get(counts, &1, 0)

    %{
      run
      | total: counts |> Map.values() |> Enum.sum(),
        done: count.("done"),
        failed: count.("error"),
        cancelled: count.("cancelled"),
        active: count.("queued") + count.("running")
    }
  end

  defp parse(%Result{status: "done"} = result, variant) do
    format = %{
      order: (variant && variant["boxOrder"]) || "xyxy",
      units: (variant && variant["boxUnits"]) || "px"
    }

    # As Meadow reads it: the tool input, or the text when the tool was never called.
    output = if result.tool_input in [nil, ""], do: result.text, else: result.tool_input
    %{result | parsed: Parser.parse(output, format, box_space(result))}
  end

  defp parse(result, _variant), do: result

  # A pixel box is a pixel of the image as the model processed it, which is smaller than
  # the image sent when that exceeded the model's limits.
  defp box_space(%Result{processed_width: width, processed_height: height})
       when is_integer(width) and is_integer(height),
       do: {width, height}

  defp box_space(%Result{sent_width: width, sent_height: height})
       when is_integer(width) and is_integer(height),
       do: {width, height}

  defp box_space(_result), do: nil

  @doc """
  Create a run and its queued results. `attrs` has `:name`, `:author`, `:file_set_ids`,
  `:models` and `:variants` (the maps the dashboard sends). The caller starts it with
  `Meadow.TranscriptionBench.Runner.start/1`.
  """
  def create_run(attrs) do
    models = attrs |> Map.get(:models, []) |> Enum.map(&String.trim/1) |> Enum.uniq()
    variants = attrs |> Map.get(:variants, []) |> List.wrap() |> Enum.uniq_by(&variant_id/1)
    file_set_ids = attrs |> Map.get(:file_set_ids, []) |> Enum.uniq()
    total = length(file_set_ids) * length(models) * length(variants)

    cond do
      total == 0 ->
        {:error, "Pick at least one image, one model and one variant"}

      total > @max_transcriptions ->
        {:error,
         "#{length(file_set_ids)} images x #{length(models)} models x #{length(variants)} " <>
           "variants is #{total} transcriptions; a run is capped at #{@max_transcriptions}"}

      Enum.any?(models, &(&1 == "")) ->
        {:error, "A model id is blank"}

      not Enum.all?(variants, &valid_variant?/1) ->
        {:error, "Every variant needs an id, a name and a prompt"}

      true ->
        with {:ok, images} <- images(file_set_ids) do
          insert_run(attrs, images, models, variants)
        end
    end
  end

  defp variant_id(%{"id" => id}), do: id
  defp variant_id(_), do: nil

  defp valid_variant?(%{"id" => id, "name" => name, "prompt" => prompt})
       when is_binary(id) and is_binary(name) and is_binary(prompt),
       do: id != "" and String.trim(prompt) != ""

  defp valid_variant?(_), do: false

  # The file sets of a run, in the order they were picked, each with the label and the
  # IIIF image URL its results keep.
  defp images(file_set_ids) do
    found =
      transcribable()
      |> where([file_set: f], f.id in ^file_set_ids)
      |> select(
        [file_set: f, core: cm],
        {f.id, f.accession_number, cm.label, cm.original_filename}
      )
      |> Repo.all()
      |> Map.new(fn {id, accession_number, label, filename} ->
        {id,
         %{
           "fileSetId" => id,
           "label" => label || filename || accession_number,
           "imageUrl" => FileSets.iiif_image_url(id)
         }}
      end)

    case Enum.reject(file_set_ids, &Map.has_key?(found, &1)) do
      [] -> {:ok, Enum.map(file_set_ids, &Map.fetch!(found, &1))}
      missing -> {:error, "Not transcribable file sets: #{Enum.join(missing, ", ")}"}
    end
  rescue
    Ecto.Query.CastError -> {:error, "A file set id is not a UUID"}
  end

  defp insert_run(attrs, images, models, variants) do
    Repo.transaction(fn ->
      run =
        %Run{}
        |> Run.changeset(%{
          name: attrs |> Map.get(:name) |> blank_to_nil(),
          author: Map.get(attrs, :author),
          variants: variants,
          images: Enum.map(images, &Map.take(&1, ["fileSetId", "label"])),
          models: models
        })
        |> Repo.insert!()

      # Image by image, so the cards of one image fill in together.
      for(image <- images, variant <- variants, model <- models, do: {image, variant, model})
      |> Enum.with_index()
      |> Enum.each(fn {{image, variant, model}, position} ->
        %Result{}
        |> Result.changeset(%{
          run_id: run.id,
          position: position,
          file_set_id: image["fileSetId"],
          label: image["label"],
          image_url: image["imageUrl"],
          model: model,
          variant_id: variant["id"]
        })
        |> Repo.insert!()
      end)

      run
    end)
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(text) do
    case String.trim(text) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  @doc """
  Queue a finished result again, as a new attempt. Returns `{:ok, run_id}`, for the
  caller to start with `Meadow.TranscriptionBench.Runner.start/1`.
  """
  def retry_result(result_id) do
    cleared = Enum.map(Result.outcome_fields() -- [:status, :image_url], &{&1, nil})

    with {:ok, uuid} <- Ecto.UUID.cast(result_id),
         {1, [run_id]} <-
           from(t in Result,
             where: t.id == ^uuid and t.status in ["done", "error", "cancelled"],
             select: t.run_id,
             update: [inc: [attempt: 1]]
           )
           |> Repo.update_all(
             set: [{:status, "queued"}, {:updated_at, DateTime.utc_now()} | cleared]
           ) do
      {:ok, run_id}
    else
      _ -> {:error, "That result does not exist, or is still running"}
    end
  end

  @doc """
  Cancel one result that is queued or transcribing. Returns `{:ok, run_id}`.

  The result is marked first, so that whatever its transcription still returns is
  dropped, and then the process transcribing it is killed, which closes its Bedrock
  stream. Bedrock bills what it had generated by then.
  """
  def cancel_result(result_id) do
    with {:ok, uuid} <- Ecto.UUID.cast(result_id),
         {1, [run_id]} <- cancel(from(t in Result, where: t.id == ^uuid, select: t.run_id)) do
      stop_transcribing(uuid)
      {:ok, run_id}
    else
      _ -> {:error, "That result does not exist, or has already finished"}
    end
  end

  @doc "Cancel every result of a run that is queued or transcribing."
  def cancel_run(run_id) do
    case Ecto.UUID.cast(run_id) do
      {:ok, uuid} ->
        {_count, ids} = cancel(from(t in Result, where: t.run_id == ^uuid, select: t.id))
        Enum.each(ids, &stop_transcribing/1)
        {:ok, uuid}

      :error ->
        {:error, "Transcription run not found"}
    end
  end

  defp cancel(query) do
    query
    |> where([t], t.status in ["queued", "running"])
    |> Repo.update_all(set: [status: "cancelled", updated_at: DateTime.utc_now()])
  end

  @doc "The registry key of the process transcribing a result, on any node."
  def transcribing_key(result_id), do: {:transcription_bench_result, result_id}

  defp stop_transcribing(result_id) do
    case Horde.Registry.lookup(Meadow.HordeRegistry, transcribing_key(result_id)) do
      [{pid, _}] -> Process.exit(pid, :kill)
      _ -> :ok
    end
  end

  @doc "Delete a run and its results. A run with transcriptions under way is kept."
  def delete_run(id) do
    case get_run(id) do
      nil -> {:error, "Transcription run not found"}
      %Run{active: active} when active > 0 -> {:error, "This run is still transcribing"}
      run -> Repo.delete(run)
    end
  end

  # ---------------------------------------------------------------------------
  # Results, as the runner writes them
  # ---------------------------------------------------------------------------

  @doc "The queued results of a run, in order."
  def queued_results(run_id) do
    from(t in Result, where: t.run_id == ^run_id and t.status == "queued", order_by: t.position)
    |> Repo.all()
  end

  @doc """
  Take a queued result for transcribing. False when another process took it first, or
  it was retried or deleted since it was read.
  """
  def claim_result(%Result{id: id, attempt: attempt}) do
    now = DateTime.utc_now()

    {count, _} =
      from(t in Result, where: t.id == ^id and t.attempt == ^attempt and t.status == "queued")
      |> Repo.update_all(set: [status: "running", started_at: now, updated_at: now])

    count == 1
  end

  @doc "Record how a claimed result ended. Nothing happens if its run was deleted."
  def finish_result(%Result{id: id, attempt: attempt}, outcome) do
    fields =
      outcome
      |> Map.take(Result.outcome_fields())
      |> Map.put(:updated_at, DateTime.utc_now())
      |> Map.to_list()

    from(t in Result, where: t.id == ^id and t.attempt == ^attempt and t.status == "running")
    |> Repo.update_all(set: fields)

    :ok
  end

  defp expire_stale do
    cutoff = DateTime.add(DateTime.utc_now(), -@stale_after_minutes * 60, :second)

    from(t in Result, where: t.status in ["queued", "running"] and t.updated_at < ^cutoff)
    |> Repo.update_all(
      set: [
        status: "error",
        error: "Interrupted: Meadow stopped before this finished.",
        updated_at: DateTime.utc_now()
      ]
    )
  end
end
