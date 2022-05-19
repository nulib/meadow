defmodule Meadow.Data.FileSets do
  @moduledoc """
  The FileSets context.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias Meadow.Config
  alias Meadow.Data.Schemas.FileSet
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
  def pyramid_uri_for(%FileSet{role: %{id: "P"}}), do: nil
  def pyramid_uri_for(%FileSet{role: %{id: "S"}}), do: nil

  def pyramid_uri_for(%FileSet{core_metadata: %{mime_type: "video/" <> _thing}}),
    do: nil

  def pyramid_uri_for(%FileSet{core_metadata: %{mime_type: "audio/" <> _thing}}),
    do: nil

  def pyramid_uri_for(%FileSet{} = file_set), do: pyramid_uri_for(file_set.id)

  def pyramid_uri_for(file_set_id) do
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
  def public_vtt_url_for(id) do
    with uri <- URI.parse(Config.iiif_manifest_url()) do
      uri
      |> URI.merge("vtt/" <> Pairtree.generate!(id) <> "/" <> id <> ".vtt")
      |> URI.to_string()
    end
  end

  def duration_in_milliseconds(%FileSet{extracted_metadata: %{"mediainfo" => mediainfo}}) do
    case mediainfo do
      %{"value" => %{"media" => %{"track" => [%{"Duration" => duration_string} | _]}}} ->
        parse_duration_string(duration_string)

      _ ->
        nil
    end
  end

  def duration_in_milliseconds(_), do: nil

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

  def access?(%{role: %{id: "A"}}), do: true
  def access?(_), do: false
  def preservation?(%{role: %{id: "P"}}), do: true
  def preservation?(_), do: false
  def auxiliary?(%{role: %{id: "X"}}), do: true
  def auxiliary?(_), do: false
  def supplemental?(%{role: %{id: "S"}}), do: true
  def supplemental?(_), do: false
end
