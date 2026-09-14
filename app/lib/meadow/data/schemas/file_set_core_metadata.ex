defmodule Meadow.Data.Schemas.FileSetCoreMetadata do
  @moduledoc """
  Core metadata for a FileSet (`file_set_core_metadata`, one row per file set).
  The preservation file's digests are columns; `digests/1` renders them as the
  `%{"md5" => ..., "sha1" => ..., "sha256" => ...}` map the rest of the app uses.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @digest_types ~w(md5 sha1 sha256)

  @primary_key false
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "file_set_core_metadata" do
    belongs_to :file_set, Meadow.Data.Schemas.FileSet, primary_key: true
    field :location, :string
    field :original_filename, :string
    field :description, :string
    field :label, :string
    field :alt_text, :string
    field :image_caption, :string
    field :mime_type, :string
    field :digest_md5, :string
    field :digest_sha1, :string
    field :digest_sha256, :string

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [
      :alt_text,
      :description,
      :image_caption,
      :label,
      :location,
      :mime_type,
      :original_filename
    ])
    |> cast_digests(params)
    |> validate_required([:location, :original_filename])
  end

  # `digests` arrives as a map (`%{"sha256" => ...}`); nil clears every digest
  defp cast_digests(changeset, params) do
    case fetch_digests(params) do
      :error ->
        changeset

      {:ok, nil} ->
        change(changeset, digest_md5: nil, digest_sha1: nil, digest_sha256: nil)

      {:ok, digests} when is_map(digests) ->
        Enum.reduce(@digest_types, changeset, &put_digest(&2, &1, digests))

      {:ok, _other} ->
        add_error(changeset, :digests, "is invalid")
    end
  end

  defp put_digest(changeset, type, digests) do
    case Map.get(digests, type) || Map.get(digests, String.to_atom(type)) do
      nil -> changeset
      value -> put_change(changeset, :"digest_#{type}", to_string(value))
    end
  end

  defp fetch_digests(params) do
    cond do
      Map.has_key?(params, "digests") -> {:ok, Map.get(params, "digests")}
      Map.has_key?(params, :digests) -> {:ok, Map.get(params, :digests)}
      true -> :error
    end
  end

  @doc "The digests as a string-keyed map, or nil when none are recorded"
  def digests(%__MODULE__{} = metadata) do
    @digest_types
    |> Enum.map(&{&1, Map.get(metadata, :"digest_#{&1}")})
    |> Enum.reject(fn {_, value} -> is_nil(value) end)
    |> case do
      [] -> nil
      pairs -> Map.new(pairs)
    end
  end

  def digests(_), do: nil
end
