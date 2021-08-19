defmodule Meadow.Utils.Pairtree do
  @moduledoc """
  Functions for working with pairtrees
  """

  @doc """
  Generates a pyramid path

  ## Examples

    iex> Pairtree.preservation_path("412ca147684a67883226c644ee46b38460b787ec34e5b240983992af4a8c0a90")
    "41/2c/a1/47/412ca147684a67883226c644ee46b38460b787ec34e5b240983992af4a8c0a90"

    iex> Pairtree.preservation_path("412ca147684a67883226c64")
    ** (ArgumentError) Invalid sha256 hash
  """
  def preservation_path(sha256) when byte_size(sha256) == 64 do
    generate!(sha256, 4) <> "/" <> sha256
  end

  def preservation_path(_) do
    raise ArgumentError, message: "Invalid sha256 hash"
  end

  @doc """
  Generate a pyramid path

  Examples:
    iex> Meadow.Utils.Pairtree.pyramid_path("a13d45b1-69a6-447f-9d42-90b989a2949c")
    "a1/3d/45/b1/-6/9a/6-/44/7f/-9/d4/2-/90/b9/89/a2/94/9c-pyramid.tif"
  """
  def pyramid_path(id) do
    id
    |> with_extension("pyramid", "tif")
  end

  @doc """
  Generate a poster path

  Examples:
    iex> Meadow.Utils.Pairtree.poster_path("a13d45b1-69a6-447f-9d42-90b989a2949c")
    "a1/3d/45/b1/-6/9a/6-/44/7f/-9/d4/2-/90/b9/89/a2/94/9c-poster.tif"
  """
  def poster_path(id) do
    id
    |> with_extension("poster", "tif")
  end

  @doc """
  Generate a manifest path

  Examples:
    iex> Meadow.Utils.Pairtree.manifest_path("a13d45b1-69a6-447f-9d42-90b989a2949c")
    "a1/3d/45/b1/-6/9a/6-/44/7f/-9/d4/2-/90/b9/89/a2/94/9c-manifest.json"
  """
  def manifest_path(id) do
    id
    |> with_extension("manifest", "json")
  end

  @doc """
  Generate an S3 Key for a IIIF manifest

  Examples:
    iex> Meadow.Utils.Pairtree.manifest_key("a13d45b1-69a6-447f-9d42-90b989a2949c")
    "public/a1/3d/45/b1/-6/9a/6-/44/7f/-9/d4/2-/90/b9/89/a2/94/9c-manifest.json"
  """
  def manifest_key(id) do
    "public/" <> with_extension(id, "manifest", "json")
  end

  @doc """
  Generate a Pairtree with ending and extension

  Examples:
    iex> Meadow.Utils.Pairtree.with_extension("a13d45b1-69a6-447f-9d42-90b989a2949c", "manifest", "json")
    "a1/3d/45/b1/-6/9a/6-/44/7f/-9/d4/2-/90/b9/89/a2/94/9c-manifest.json"
  """

  def with_extension(id, ending, extension) do
    generate!(id) <> "-" <> ending <> "." <> extension
  end

  @doc """
  Generate a pairtree

  Examples:
    iex> Meadow.Utils.Pairtree.generate("abcdef")
    {:ok, "ab/cd/ef"}

    iex> Meadow.Utils.Pairtree.generate("abcdef", "string")
    {:error, "length must be nil or integer"}

    # Odd number of characters
    iex> Meadow.Utils.Pairtree.generate("abcdefg")
    {:ok, "ab/cd/ef"}

    # Partial path
    iex> Meadow.Utils.Pairtree.generate("abcdefghijklm", 3)
    {:ok, "ab/cd/ef"}

    # Too short for partial
    iex> Meadow.Utils.Pairtree.generate("ABCDEFGH", 8)
    {:ok, "ab/cd/ef/gh"}

    # Bad length
    iex> Meadow.Utils.Pairtree.generate("ABCDEFGH", "foo")
    {:error, "length must be nil or integer"}
  """
  def generate(id, length \\ nil) do
    transform = fn str ->
      Regex.scan(~r/../, str)
      |> Enum.join("/")
      |> String.downcase()
    end

    case length do
      nil -> {:ok, id |> transform.()}
      x when is_integer(x) -> {:ok, id |> String.slice(0, length * 2) |> transform.()}
      _ -> {:error, "length must be nil or integer"}
    end
  end

  @doc """
  Same as `generate/2` but raises on error

    Examples:
    # Full length
    iex> Meadow.Utils.Pairtree.generate!("abcdef")
    "ab/cd/ef"

    # Partial
    iex> Meadow.Utils.Pairtree.generate!("abcdef", 2)
    "ab/cd"

    # Odd number of characters
    iex> Meadow.Utils.Pairtree.generate!("abcdefg")
    "ab/cd/ef"

    # Too short for partial
    iex> Meadow.Utils.Pairtree.generate!("abcdefg", 8)
    "ab/cd/ef"

    # Bad length
    iex> Meadow.Utils.Pairtree.generate!("abcdefg", "foo")
    ** (ArgumentError) length must be nil or integer
  """
  def generate!(id, length \\ nil) do
    case generate(id, length) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message
    end
  end
end
