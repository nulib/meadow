defmodule Meadow.Data.FileSets do
  @moduledoc """
  The FileSets context.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias Meadow.AI.Provenance
  alias Meadow.Config
  alias Meadow.Data.Transcriber
  alias Meadow.Data.Schemas.{FileSet, FileSetAnnotation}
  alias Meadow.Pipeline.Actions.GeneratePosterImage
  alias Meadow.Repo
  alias Meadow.Utils.Pairtree

  require Logger

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
    Repo.exists?(from(f in FileSet, where: f.accession_number == ^accession_number))
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
  Replaces (versions) a FileSet.
  """
  def replace_file_set(%FileSet{} = file_set, attrs) do
    changeset =
      FileSet.update_changeset(file_set, attrs)
      |> validate_poster_offset(file_set)

    response = Repo.update(changeset)

    case response do
      {:ok, _file_set} -> post_process(changeset)
      other -> other
    end

    response
  end

  @doc """
  Updates a FileSet.
  """
  def update_file_set(%FileSet{} = file_set, attrs) do
    changeset =
      FileSet.update_changeset(file_set, attrs)
      |> validate_poster_offset(file_set)

    response = Repo.update(changeset)

    case response do
      {:ok, _file_set} -> post_process(changeset)
      other -> other
    end

    response
  end

  defp validate_poster_offset(%{changes: %{poster_offset: poster_offset}} = changeset, file_set)
       when is_integer(poster_offset) do
    duration = duration_in_milliseconds(file_set)

    if poster_offset > duration do
      add_error(
        changeset,
        :poster_offset,
        "Poster offset #{poster_offset} must be less than #{duration}"
      )
    else
      changeset
    end
  end

  defp validate_poster_offset(changeset, _file_set), do: changeset

  defp post_process(%{changes: %{poster_offset: poster_offset}} = changeset)
       when is_integer(poster_offset) do
    Task.async(fn -> changeset.data.id |> get_file_set!() |> GeneratePosterImage.process(%{}) end)
  end

  defp post_process(_), do: :noop

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

  def derivative_location(file_set) do
    dest_bucket = Config.pyramid_bucket()

    dest_key =
      Path.join([
        "/",
        "derivatives",
        Pairtree.derivative_path(file_set.id)
      ])

    %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()
  end

  def derivative_key(file_set) do
    Path.join([
      "derivatives",
      Pairtree.derivative_path(file_set.id)
    ])
  end

  def download_uri_for(%FileSet{id: id, role: %{id: "X"}}), do: download_uri(id)
  def download_uri_for(%FileSet{id: id, role: %{id: "A"}}), do: download_uri(id)
  def download_uri_for(_), do: nil

  defp download_uri(id) do
    api_url = Application.get_env(:meadow, :dc_api) |> get_in([:v2, "base_url"])
    "#{api_url}/file-sets/#{id}/download"
  end

  defp multi_update(file_set_updates) do
    file_set_updates
    |> Enum.with_index(1)
    |> Enum.reduce(Multi.new(), fn {changes, index}, multi ->
      Multi.update(
        multi,
        :"index_#{index}",
        FileSet.update_changeset(get_file_set!(changes.id), prep_changes(changes))
      )
    end)
    |> Repo.transaction()
  end

  defp prep_changes(changes) do
    Enum.filter(changes, fn {k, _v} -> Enum.member?([:structural_metadata, :core_metadata], k) end)
    |> Enum.into(%{})
    |> Map.put(:updated_at, NaiveDateTime.utc_now())
  end

  @spec compute_positions(any) :: list
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
  Get the representative image url for a file set. Could be a pyramid, poster, or nil
  """
  def representative_image_url_for(
        %FileSet{derivatives: %{"pyramid_tiff" => _pyramid}} = file_set
      ) do
    with uri <- URI.parse(Meadow.Config.iiif_server_url()) do
      uri
      |> URI.merge(file_set.id)
      |> URI.to_string()
    end
  end

  def representative_image_url_for(%FileSet{derivatives: %{"poster" => _poster}} = file_set) do
    with uri <- URI.parse(Meadow.Config.iiif_server_url()) do
      uri
      |> URI.merge("posters/#{file_set.id}")
      |> URI.to_string()
    end
  end

  def representative_image_url_for(_), do: nil

  @doc """
  Get the pyramid path for a file set
  """
  def pyramid_uri_for(
        %FileSet{role: %{id: "A"}, core_metadata: %{mime_type: "image/" <> _thing}} = file_set
      ),
      do: pyramid_uri_from_id(file_set.id)

  def pyramid_uri_for(
        %FileSet{role: %{id: "X"}, core_metadata: %{mime_type: "image/" <> _thing}} = file_set
      ),
      do: pyramid_uri_from_id(file_set.id)

  def pyramid_uri_for(_), do: nil

  defp pyramid_uri_from_id(file_set_id) do
    dest_bucket = Config.pyramid_bucket()

    dest_key = Path.join(["/", Pairtree.pyramid_path(file_set_id)])

    %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()
  end

  def preservation_location(file_set) do
    dest_bucket = Config.preservation_bucket()

    dest_key =
      Path.join([
        "/",
        Pairtree.preservation_path(file_set.id)
      ])

    %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()
  end

  def poster_uri_for(%FileSet{} = file_set), do: poster_uri_for(file_set.id)

  def poster_uri_for(file_set_id) do
    dest_bucket = Config.pyramid_bucket()

    dest_key = Path.join(["/posters/", Pairtree.poster_path(file_set_id)])

    %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()
  end

  @doc """
  Get the distribution streaming playlist url for a file set
  """
  def distribution_streaming_uri_for(%FileSet{derivatives: %{"playlist" => playlist}})
      when is_binary(playlist) and byte_size(playlist) > 0 do
    with %{path: path} <- URI.parse(playlist) do
      Config.streaming_url() |> Path.join(path)
    end
  rescue
    FunctionClauseError -> nil
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

  @doc """
  Get the path (key) for a structural metadata file (vtt) for a file set
  """
  def vtt_location(id), do: Path.join("public/vtt/" <> Pairtree.generate!(id), id <> ".vtt")

  @doc """
  Get the path for a structural metadata file (vtt) for a file set
  """
  def public_vtt_url_for(%{structural_metadata: %{type: "webvtt", value: _value}} = file_set) do
    with uri <- URI.parse(Config.iiif_manifest_url_deprecated()) do
      uri
      |> URI.merge("vtt/" <> Pairtree.generate!(file_set.id) <> "/" <> file_set.id <> ".vtt")
      |> URI.to_string()
    end
  end

  def public_vtt_url_for(_), do: nil

  def duration_in_milliseconds(%FileSet{extracted_metadata: %{"mediainfo" => mediainfo}}) do
    case mediainfo do
      %{"value" => %{"media" => %{"track" => [%{"Duration" => duration_string} | _]}}} ->
        parse_duration_string(duration_string)

      _ ->
        nil
    end
  end

  def duration_in_milliseconds(_), do: nil

  def duration_in_seconds(file_set) do
    case duration_in_milliseconds(file_set) do
      nil ->
        nil

      0 ->
        nil

      milliseconds ->
        milliseconds / 1000
    end
  end

  defp parse_duration_string(value) when is_binary(value) do
    case Float.parse(value) do
      {duration, _} -> duration * 1000
      :error -> nil
    end
  end

  defp parse_duration_string(_), do: nil

  def height(%FileSet{
        role: %{id: "A"},
        extracted_metadata: %{"mediainfo" => mediainfo},
        core_metadata: %{mime_type: "video/" <> _}
      }) do
    with {height, _} <-
           Integer.parse(
             get_in(mediainfo, [
               "value",
               "media",
               "track",
               Access.at(1),
               "Height"
             ])
           ) do
      height
    end
  end

  def height(%FileSet{extracted_metadata: %{"exif" => %{"value" => %{"ImageHeight" => height}}}}),
    do: height

  def height(_), do: nil

  def width(%FileSet{
        role: %{id: "A"},
        extracted_metadata: %{"mediainfo" => mediainfo},
        core_metadata: %{mime_type: "video/" <> _}
      }) do
    with {width, _} <-
           Integer.parse(
             get_in(mediainfo, [
               "value",
               "media",
               "track",
               Access.at(1),
               "Width"
             ])
           ) do
      width
    end
  end

  def width(%FileSet{extracted_metadata: %{"exif" => %{"value" => %{"ImageWidth" => width}}}}),
    do: width

  def width(_), do: nil

  def aspect_ratio(file_set) do
    width = width(file_set)
    height = height(file_set)

    if width && height, do: Float.floor(width / height, 5), else: nil
  end

  def access?(%{role: %{id: "A"}}), do: true
  def access?(_), do: false
  def preservation?(%{role: %{id: "P"}}), do: true
  def preservation?(_), do: false
  def auxiliary?(%{role: %{id: "X"}}), do: true
  def auxiliary?(_), do: false
  def supplemental?(%{role: %{id: "S"}}), do: true
  def supplemental?(_), do: false

  @doc """
  Write annotation content to the database.

  ## Examples

      iex> write_annotation_content(%FileSetAnnotation{}, "This is the transcription text")
      {:ok, %FileSetAnnotation{}}

  """
  def write_annotation_content(%FileSetAnnotation{} = annotation, content)
      when is_binary(content) do
    update_annotation(annotation, %{content: content})
  end

  @doc """
  Copy annotation content from a source S3 location into the database.

  ## Examples

      iex> copy_annotation_content(%FileSetAnnotation{}, "source-bucket", "path/to/source.txt")
      {:ok, %FileSetAnnotation{}}

  """
  def copy_annotation_content(%FileSetAnnotation{} = annotation, source_bucket, source_key) do
    case ExAws.S3.get_object(source_bucket, source_key) |> ExAws.request() do
      {:ok, %{body: body}} -> write_annotation_content(annotation, body)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Read annotation content from the database.

  ## Examples

      iex> read_annotation_content(%FileSetAnnotation{content: "This is the transcription text"})
      {:ok, "This is the transcription text"}

  """
  def read_annotation_content(%FileSetAnnotation{content: content})
      when is_binary(content),
      do: {:ok, content}

  def read_annotation_content(_), do: {:error, :no_content}

  @doc """
  Transcribes a file set using AI and stores the result as an annotation.

  This function creates an annotation record with status "pending" and kicks off
  the transcription process in the background. The annotation is returned immediately
  so the client can monitor its status via subscription.

  ## Options

    * `:language` - Language codes for the transcription (default: ["en"])
    * `:model` - AI model identifier (default: from config)
    * `:prompt` - Custom prompt for transcription
    * `:max_tokens` - Maximum tokens for generation

  ## Examples

      iex> transcribe_file_set("file-set-id")
      {:ok, %FileSetAnnotation{status: "pending", id: "..."}}

      iex> transcribe_file_set("invalid-id")
      {:error, reason}

  """
  def transcribe_file_set(file_set_id, opts \\ []) when is_binary(file_set_id) do
    with {:ok, file_set} <- fetch_file_set_for_transcription(file_set_id),
         {:ok, annotation} <- create_pending_annotation(file_set, opts) do
      Task.start(fn -> process_transcription(annotation, opts) end)
      {:ok, annotation}
    end
  end

  defp process_transcription(annotation, opts) do
    {:ok, annotation} = update_annotation(annotation, %{status: "in_progress"})

    handle_transcription_result(
      annotation,
      transcriber().transcribe(annotation.file_set_id, opts)
    )
  end

  defp publish_annotation_error(annotation, reason) do
    payload = %{annotation | status: "error", error: format_transcription_error(reason)}

    Absinthe.Subscription.publish(MeadowWeb.Endpoint, payload,
      file_set_annotation: annotation.file_set_id
    )
  end

  defp format_transcription_error({:bedrock_stream_failed, %{message: msg}})
       when is_binary(msg),
       do: "Transcription service error: #{msg}"

  defp format_transcription_error({:bedrock_stream_failed, error}),
    do: "Transcription service error: #{inspect(error)}"

  defp format_transcription_error({:image_fetch_failed, status, _body}),
    do: "Could not fetch source image (HTTP #{status})"

  defp format_transcription_error({:image_fetch_error, reason}),
    do: "Could not fetch source image: #{inspect(reason)}"

  defp format_transcription_error({:no_representative_image, _id}),
    do: "No representative image available for transcription"

  defp format_transcription_error({:invalid_transcriber_model, model}),
    do: "Invalid transcriber model: #{inspect(model)}"

  defp format_transcription_error({:file_set_not_found, _id}),
    do: "File set not found"

  defp format_transcription_error(:blank_transcription),
    do: "The transcription service returned no text"

  defp format_transcription_error(reason), do: inspect(reason)

  # Resolved at runtime (not via compile_env) so Mox can swap the implementation per test.
  defp transcriber do
    Application.get_env(:meadow, :transcriber, Transcriber)
  end

  defp handle_transcription_result(annotation, {:ok, %{text: ""}}),
    do: mark_blank_transcription_error(annotation)

  defp handle_transcription_result(annotation, {:ok, %{text: nil}}),
    do: mark_blank_transcription_error(annotation)

  defp handle_transcription_result(annotation, {:ok, %{text: text} = transcription})
       when is_binary(text) do
    Repo.transaction(fn ->
      updated_annotation =
        annotation
        |> update_annotation(%{
          status: "completed",
          content: transcription.text,
          language: transcription.languages
        })
        |> unwrap_or_rollback()

      record_completed_transcription_provenance(updated_annotation, transcription)
      |> unwrap_or_rollback()

      updated_annotation
    end)
  end

  defp handle_transcription_result(annotation, {:error, reason}) do
    result =
      Repo.transaction(fn ->
        updated_annotation =
          annotation
          |> update_annotation(%{status: "error"})
          |> unwrap_or_rollback()

        record_failed_transcription_provenance(updated_annotation, reason)
        |> unwrap_or_rollback()

        updated_annotation
      end)

    publish_annotation_error(annotation, reason)
    result
  end

  defp mark_blank_transcription_error(annotation) do
    Logger.warning(
      "Transcription for file set #{annotation.file_set_id} returned blank text; marking annotation as error"
    )

    result =
      Repo.transaction(fn ->
        updated_annotation =
          annotation
          |> update_annotation(%{status: "error"})
          |> unwrap_or_rollback()

        record_failed_transcription_provenance(updated_annotation, :blank_transcription)
        |> unwrap_or_rollback()

        updated_annotation
      end)

    publish_annotation_error(annotation, :blank_transcription)
    result
  end

  defp fetch_file_set_for_transcription(file_set_id) do
    case Repo.get(FileSet, file_set_id) |> Repo.preload(work: []) do
      nil ->
        {:error, {:file_set_not_found, file_set_id}}

      %FileSet{role: %{id: role_id}} when role_id != "A" ->
        {:error, :invalid_role}

      %FileSet{work: %{work_type: %{id: work_type_id}}} when work_type_id != "IMAGE" ->
        {:error, :invalid_work_type}

      %FileSet{} = file_set ->
        {:ok, file_set}
    end
  end

  defp create_pending_annotation(file_set, opts) do
    model = Keyword.get(opts, :model, Config.ai(:transcriber_model))
    language = Keyword.get(opts, :language, ["en"])
    context = Keyword.get(opts, :context)
    actor = Keyword.get(opts, :actor)

    # Only one transcription is allowed per file set, so regenerating replaces any
    # existing one. Resolve the new origin against the annotation being replaced
    # *before* it is deleted: seeding the model with human-authored content makes
    # the result an AI modification of human content, not a fresh generation.
    existing = Repo.get_by(FileSetAnnotation, file_set_id: file_set.id, type: "transcription")
    origin = regeneration_origin(context, existing)

    Repo.transaction(fn ->
      if existing do
        Provenance.record_annotation_deletion(existing, actor)
        Repo.delete(existing) |> unwrap_or_rollback()
      end

      activity =
        %{
          activity_type: "transcription",
          model: model,
          ai_use_type: "transcription",
          access_mode: "controlled_internal_model",
          reversibility: "reversible",
          model_type: "transcription",
          input: %{
            file_set_id: file_set.id,
            language: language,
            context_used: present?(context),
            transcription_origin: origin
          },
          work_id: file_set.work_id,
          file_set_id: file_set.id
        }
        |> Provenance.create_activity()
        |> unwrap_or_rollback()

      Provenance.add_source(activity, Provenance.file_set_source_attrs(file_set))
      |> unwrap_or_rollback()

      create_annotation(file_set, %{
        type: "transcription",
        status: "pending",
        language: language,
        model: model,
        ai_activity_id: activity.id
      })
      |> unwrap_or_rollback()
    end)
  end

  defp record_completed_transcription_provenance(
         %{ai_activity_id: activity_id} = annotation,
         transcription
       )
       when not is_nil(activity_id) do
    activity = Provenance.get_activity!(activity_id)
    origin = transcription_origin(activity)

    # A generation seeded with human content is an AI *modification* of that
    # content, so reflect it in the IPTC source type (algorithmicallyEnhanced)
    # and C2PA action (edited) — otherwise it is purely AI-generated.
    {source_type, c2pa_action} =
      if origin == "ai_modified_human_content" do
        {Provenance.enhanced_source_type(), "c2pa.edited"}
      else
        {Provenance.trained_source_type(), "c2pa.created"}
      end

    Provenance.record_target(
      activity,
      %{
        target_type: "FileSetAnnotation",
        target_id: annotation.id,
        field_path: "file_set_annotations.content",
        operation: "replace",
        proposed_value: transcription.text,
        origin: origin,
        status: "applied",
        premis_object_category: "representation",
        object_identifier_type: "Meadow FileSetAnnotation",
        object_identifier_value: annotation.id,
        c2pa_action: c2pa_action,
        digital_source_type_uri: source_type,
        ingredient_relationship: "componentOf",
        human_oversight_level: "human_review_required",
        c2pa_assertion_label: "c2pa.ai-disclosure"
      },
      "applied"
    )
    |> unwrap_or_rollback()

    Provenance.complete_activity(activity, %{
      output: %{text: transcription.text, languages: transcription.languages}
    })
  end

  defp record_completed_transcription_provenance(_annotation, _transcription), do: :ok

  # The new transcription's origin, resolved when the pending annotation is
  # created and stashed on the activity input. Defaults to a pure AI generation.
  defp regeneration_origin(context, existing) do
    if present?(context) and modifies_human_content?(existing) do
      "ai_modified_human_content"
    else
      "ai_generated"
    end
  end

  # Whether the annotation being replaced carries human-authored content. An
  # annotation with no AI activity (or none recorded) is human; one whose latest
  # provenance origin is anything other than a pristine `ai_generated` has had a
  # human hand in it. A pure AI transcription has not.
  defp modifies_human_content?(nil), do: true
  defp modifies_human_content?(%FileSetAnnotation{ai_activity_id: nil}), do: true

  defp modifies_human_content?(%FileSetAnnotation{id: id}) do
    case Provenance.target_summary("FileSetAnnotation", id) |> List.first() do
      %{origin: "ai_generated"} -> false
      %{origin: _} -> true
      _ -> true
    end
  end

  defp transcription_origin(%{input: input}) when is_map(input) do
    case input["transcription_origin"] || input[:transcription_origin] do
      origin when origin in ["ai_generated", "ai_modified_human_content"] -> origin
      _ -> "ai_generated"
    end
  end

  defp transcription_origin(_), do: "ai_generated"

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_), do: false

  defp record_failed_transcription_provenance(%{ai_activity_id: activity_id}, reason)
       when not is_nil(activity_id) do
    activity = Provenance.get_activity!(activity_id)

    Enum.each(activity.targets, fn target ->
      Provenance.add_event(target, %{event_type: "failed", notes: inspect(reason)})
      |> unwrap_or_rollback()
    end)

    Provenance.fail_activity(activity, reason)
  end

  defp record_failed_transcription_provenance(_annotation, _reason), do: :ok

  defp unwrap_or_rollback(:ok), do: :ok
  defp unwrap_or_rollback({:ok, result}), do: result
  defp unwrap_or_rollback({:error, reason}), do: Repo.rollback(reason)

  @doc """
  Updates the content of an annotation in S3 and updates the annotation record.

  ## Options

    * `:language` - List of ISO 639 language codes to update

  ## Examples

      iex> update_annotation_content("annotation-id", "Updated transcription text")
      {:ok, %FileSetAnnotation{}}

      iex> update_annotation_content("annotation-id", "text", %{language: ["lg", "en"]})
      {:ok, %FileSetAnnotation{}}

      iex> update_annotation_content("invalid-id", "text")
      {:error, :not_found}

  """
  def update_annotation_content(annotation_id, content, opts \\ %{}) when is_binary(content) do
    with %FileSetAnnotation{} = annotation <-
           get_annotation(annotation_id) || {:error, :not_found} do
      opts = Enum.into(opts, %{})
      attrs = Map.merge(%{content: content}, Map.take(opts, [:language]))

      with {:ok, updated} <- update_annotation(annotation, attrs) do
        # Record a direct human edit of AI-generated annotation content (e.g. an
        # AI transcription edited in the Access Files modal) so the provenance
        # origin reflects human mediation ("AI + human edited") instead of
        # silently staying "AI generated". No-op for annotations without AI
        # provenance or when the content is unchanged. Uses the in-memory
        # annotation, which still carries the prior content + ai_activity_id.
        Provenance.record_annotation_manual_edit(annotation, content, Map.get(opts, :actor))
        {:ok, updated}
      end
    end
  end

  @doc """
  Mark an AI-generated annotation's live content as human-authored, preserving
  its AI provenance history (see `Provenance.record_annotation_human_attestation/3`).
  Does not change the annotation's content. Returns `{:ok, annotation}` on
  success, `{:error, :not_found}` for a missing annotation, or the provenance
  error (e.g. `{:error, :no_ai_provenance}`).

  ## Options

    * `:actor` - username taking responsibility for the value (required)
    * `:reason` - optional note stored on the attestation event
  """
  def attest_annotation_content(annotation_id, opts \\ %{}) do
    opts = Enum.into(opts, %{})

    with %FileSetAnnotation{} = annotation <-
           get_annotation(annotation_id) || {:error, :not_found} do
      case Provenance.record_annotation_human_attestation(
             annotation,
             Map.get(opts, :actor),
             reason: Map.get(opts, :reason)
           ) do
        :ok -> {:ok, annotation}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Creates or updates a completed annotation for a file set by type.

  Geographic annotation types are validated before persistence:

    * `nav_place` content must be a GeoJSON FeatureCollection.
    * `georeference` content must be a IIIF Georeference Annotation.
  """
  def upsert_annotation_content(file_set_id, type, content, opts \\ %{})
      when is_binary(file_set_id) and is_binary(type) and is_binary(content) do
    with %FileSet{} = file_set <- get_file_set(file_set_id) || {:error, :file_set_not_found},
         :ok <- validate_annotation_content(type, content) do
      opts = Enum.into(opts, %{})

      attrs =
        %{
          content: content,
          status: "completed"
        }
        |> Map.merge(Map.take(opts, [:language]))

      case Repo.get_by(FileSetAnnotation, file_set_id: file_set.id, type: type) do
        nil ->
          create_annotation(file_set, Map.put(attrs, :type, type))

        %FileSetAnnotation{} = annotation ->
          update_annotation(annotation, attrs)
      end
    end
  end

  defp validate_annotation_content("nav_place", content) do
    case decode_annotation_json(content) do
      {:ok, decoded} -> validate_nav_place(decoded)
      error -> error
    end
  end

  defp validate_annotation_content("georeference", content) do
    case decode_annotation_json(content) do
      {:ok, decoded} -> validate_georeference(decoded)
      error -> error
    end
  end

  defp validate_annotation_content(_, _), do: :ok

  defp decode_annotation_json(content) do
    case Jason.decode(content) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, _} -> {:error, {:invalid_annotation_content, "content must be valid JSON"}}
    end
  end

  defp validate_nav_place(%{"type" => "FeatureCollection", "features" => features})
       when is_list(features) and features != [] do
    if Enum.all?(features, &valid_geojson_feature?/1) do
      :ok
    else
      {:error,
       {:invalid_annotation_content,
        "nav_place features must include valid GeoJSON geometries with coordinate pairs"}}
    end
  end

  defp validate_nav_place(_) do
    {:error,
     {:invalid_annotation_content,
      "nav_place content must be a non-empty GeoJSON FeatureCollection"}}
  end

  defp validate_georeference(
         %{
           "@context" => context,
           "type" => "Annotation",
           "motivation" => "georeferencing",
           "target" => %{"source" => source},
           "body" => %{"type" => "FeatureCollection", "features" => features}
         } = annotation
       )
       when is_list(features) and features != [] and is_map(source) do
    cond do
      not georeference_context?(context) ->
        {:error,
         {:invalid_annotation_content,
          "georeference annotation must include the IIIF georeference context"}}

      is_nil(get_in(annotation, ["target", "source", "id"])) ->
        {:error,
         {:invalid_annotation_content, "georeference annotation target source must include an id"}}

      Enum.all?(features, &valid_georeference_feature?/1) ->
        :ok

      true ->
        {:error,
         {:invalid_annotation_content,
          "georeference features must include geographic coordinates and resourceCoords"}}
    end
  end

  defp validate_georeference(_) do
    {:error,
     {:invalid_annotation_content,
      "georeference content must be a IIIF Annotation with georeferencing motivation and a FeatureCollection body"}}
  end

  defp georeference_context?(context) when is_binary(context),
    do: String.contains?(context, "georef")

  defp georeference_context?(context) when is_list(context) do
    Enum.any?(context, fn
      value when is_binary(value) -> String.contains?(value, "georef")
      _ -> false
    end)
  end

  defp georeference_context?(_), do: false

  defp valid_geojson_feature?(%{
         "type" => "Feature",
         "geometry" => nil,
         "properties" => properties
       })
       when is_map(properties) or is_nil(properties),
       do: true

  defp valid_geojson_feature?(%{
         "type" => "Feature",
         "geometry" => geometry,
         "properties" => properties
       })
       when is_map(properties) or is_nil(properties) do
    valid_geojson_geometry?(geometry)
  end

  defp valid_geojson_feature?(_), do: false

  defp valid_geojson_geometry?(%{"type" => "Point", "coordinates" => position}),
    do: valid_geo_position?(position)

  defp valid_geojson_geometry?(%{"type" => "MultiPoint", "coordinates" => positions})
       when is_list(positions),
       do: Enum.all?(positions, &valid_geo_position?/1)

  defp valid_geojson_geometry?(%{"type" => "LineString", "coordinates" => positions}),
    do: valid_geo_line_string?(positions)

  defp valid_geojson_geometry?(%{"type" => "MultiLineString", "coordinates" => lines})
       when is_list(lines),
       do: Enum.all?(lines, &valid_geo_line_string?/1)

  defp valid_geojson_geometry?(%{"type" => "Polygon", "coordinates" => rings}),
    do: valid_geo_polygon?(rings)

  defp valid_geojson_geometry?(%{"type" => "MultiPolygon", "coordinates" => polygons})
       when is_list(polygons),
       do: Enum.all?(polygons, &valid_geo_polygon?/1)

  defp valid_geojson_geometry?(%{"type" => "GeometryCollection", "geometries" => geometries})
       when is_list(geometries),
       do: Enum.all?(geometries, &valid_geojson_geometry?/1)

  defp valid_geojson_geometry?(_), do: false

  defp valid_georeference_feature?(%{
         "type" => "Feature",
         "geometry" => %{"coordinates" => coords},
         "properties" => %{"resourceCoords" => resource_coords}
       }) do
    valid_geo_coordinate_pair?(coords) and valid_numeric_pair?(resource_coords)
  end

  defp valid_georeference_feature?(_), do: false

  defp valid_geo_line_string?(positions) when is_list(positions) and length(positions) >= 2,
    do: Enum.all?(positions, &valid_geo_position?/1)

  defp valid_geo_line_string?(_), do: false

  defp valid_geo_polygon?(rings) when is_list(rings) and rings != [],
    do: Enum.all?(rings, &valid_geo_linear_ring?/1)

  defp valid_geo_polygon?(_), do: false

  defp valid_geo_linear_ring?(positions) when is_list(positions) and length(positions) >= 4 do
    Enum.all?(positions, &valid_geo_position?/1) and List.first(positions) == List.last(positions)
  end

  defp valid_geo_linear_ring?(_), do: false

  defp valid_geo_position?([lng, lat | rest])
       when is_number(lng) and is_number(lat) and is_list(rest) do
    valid_geo_coordinate_pair?([lng, lat]) and Enum.all?(rest, &is_number/1)
  end

  defp valid_geo_position?(_), do: false

  defp valid_geo_coordinate_pair?([lng, lat])
       when is_number(lng) and is_number(lat) and lng >= -180 and lng <= 180 and lat >= -90 and
              lat <= 90,
       do: true

  defp valid_geo_coordinate_pair?(_), do: false

  defp valid_numeric_pair?([x, y]) when is_number(x) and is_number(y), do: true
  defp valid_numeric_pair?(_), do: false

  @doc """
  Creates an annotation for a file set.

  ## Examples

      iex> create_annotation(%FileSet{id: "123"}, %{type: "transcription", status: "pending"})
      {:ok, %FileSetAnnotation{}}

      iex> create_annotation(%FileSet{id: "123"}, %{type: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_annotation(%FileSet{id: file_set_id}, attrs) do
    attrs
    |> Map.put(:file_set_id, file_set_id)
    |> create_annotation()
  end

  def create_annotation(attrs) when is_map(attrs) do
    %FileSetAnnotation{}
    |> FileSetAnnotation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets an annotation by id.
  """
  def get_annotation(id), do: Repo.get(FileSetAnnotation, id)

  @doc """
  Gets an annotation by id, raising if not found.
  """
  def get_annotation!(id), do: Repo.get!(FileSetAnnotation, id)

  @doc """
  Lists all annotations for a file set.

  ## Examples

      iex> list_annotations(%FileSet{id: "123"})
      [%FileSetAnnotation{}, ...]

      iex> list_annotations("file-set-id")
      [%FileSetAnnotation{}, ...]

  """
  def list_annotations(%FileSet{id: file_set_id}) do
    list_annotations(file_set_id)
  end

  def list_annotations(file_set_id) when is_binary(file_set_id) do
    from(a in FileSetAnnotation, where: a.file_set_id == ^file_set_id)
    |> Repo.all()
  end

  @doc """
  Updates an annotation.

  ## Examples

      iex> update_annotation(%FileSetAnnotation{}, %{status: "completed"})
      {:ok, %FileSetAnnotation{}}

  """
  def update_annotation(%FileSetAnnotation{} = annotation, attrs) do
    annotation
    |> FileSetAnnotation.changeset(attrs)
    |> Repo.update(stale_error_field: :id)
  end

  @doc """
  Deletes an annotation.
  """
  def delete_annotation(%FileSetAnnotation{} = annotation, actor \\ nil) do
    with {:ok, deleted} <- Repo.delete(annotation) do
      # Record the disposition of AI-generated content (e.g. a transcription) so
      # the provenance trail reflects the human removal. No-op for annotations
      # without AI provenance. Uses the in-memory annotation (which still carries
      # content + ai_activity_id) since the row is now gone.
      Provenance.record_annotation_deletion(annotation, actor)
      {:ok, deleted}
    end
  end
end
