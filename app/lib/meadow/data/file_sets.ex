defmodule Meadow.Data.FileSets do
  @moduledoc """
  The FileSets context.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias Meadow.Config
  alias Meadow.Data.Schemas.{FileSet, FileSetAnnotation}
  alias Meadow.Pipeline.Actions.GeneratePosterImage
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
  def pyramid_uri_for(%FileSet{role: %{id: "A"}, core_metadata: %{mime_type: "image/" <> _thing}} = file_set),
    do: pyramid_uri_from_id(file_set.id)

  def pyramid_uri_for(%FileSet{role: %{id: "X"}, core_metadata: %{mime_type: "image/" <> _thing}} = file_set),
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
  Get the S3 location for an annotation file.

  ## Examples

      iex> annotation_location(%FileSetAnnotation{id: "123", file_set_id: "456", type: "transcription"})
      "s3://bucket-name/annotations/45/6-/transcription-123.txt"

  """
  def annotation_location(%FileSetAnnotation{id: id, file_set_id: file_set_id, type: type}) do
    dest_bucket = Config.derivatives_bucket()
    dest_key = annotation_key(file_set_id, id, type)
    %URI{scheme: "s3", host: dest_bucket, path: "/#{dest_key}"} |> URI.to_string()
  end

  @doc """
  Get the S3 key (path) for an annotation file.
  """
  def annotation_key(file_set_id, annotation_id, type) do
    # Using pairtree for file_set_id to avoid too many files in one directory
    pairtree = Pairtree.generate!(file_set_id)
    "annotations/#{pairtree}/#{type}-#{annotation_id}.txt"
  end

  @doc """
  Write annotation content to S3.

  ## Examples

      iex> write_annotation_content(%FileSetAnnotation{}, "This is the transcription text")
      {:ok, "s3://bucket/path/to/file.txt"}

  """
  def write_annotation_content(%FileSetAnnotation{} = annotation, content) when is_binary(content) do
    location = annotation_location(annotation)
    %URI{host: bucket, path: "/" <> key} = URI.parse(location)

    case ExAws.S3.put_object(bucket, key, content, content_type: "text/plain; charset=utf-8")
         |> ExAws.request() do
      {:ok, _} -> {:ok, location}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Read annotation content from S3.

  ## Examples

      iex> read_annotation_content(%FileSetAnnotation{s3_location: "s3://..."})
      {:ok, "This is the transcription text"}

  """
  def read_annotation_content(%FileSetAnnotation{s3_location: location}) when is_binary(location) do
    %URI{host: bucket, path: "/" <> key} = URI.parse(location)

    case ExAws.S3.get_object(bucket, key) |> ExAws.request() do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  def read_annotation_content(_), do: {:error, :no_s3_location}

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
      # Kick off transcription in background
      Task.start(fn -> process_transcription(annotation, opts) end)
      {:ok, annotation}
    end
  end

  defp process_transcription(annotation, opts) do
    alias Meadow.Data.Transcriber

    # Update to in_progress
    {:ok, annotation} = update_annotation(annotation, %{status: "in_progress"})

    case Transcriber.transcribe(annotation.file_set_id, opts) do
      {:ok, transcription} ->
        case write_annotation_content(annotation, transcription.text) do
          {:ok, s3_location} ->
            update_annotation(annotation, %{
              status: "completed",
              s3_location: s3_location,
              language: transcription.languages
            })

          {:error, _reason} ->
            update_annotation(annotation, %{status: "error"})
        end

      {:error, _reason} ->
        update_annotation(annotation, %{status: "error"})
    end
  end

  defp fetch_file_set_for_transcription(file_set_id) do
    case Repo.get(FileSet, file_set_id) |> Repo.preload(work: []) do
      nil ->
        {:error, :file_set_not_found}

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

    create_annotation(file_set, %{
      type: "transcription",
      status: "pending",
      language: language,
      model: model
    })
  end

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
    case get_annotation(annotation_id) do
      nil ->
        {:error, :not_found}

      annotation ->
        update_attrs = %{s3_location: nil}
        update_attrs = if opts[:language], do: Map.put(update_attrs, :language, opts[:language]), else: update_attrs

        with {:ok, s3_location} <- write_annotation_content(annotation, content) do
          update_annotation(annotation, Map.put(update_attrs, :s3_location, s3_location))
        end
    end
  end

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
    |> Repo.update()
  end

  @doc """
  Deletes an annotation.
  """
  def delete_annotation(%FileSetAnnotation{} = annotation) do
    Repo.delete(annotation)
  end
end
