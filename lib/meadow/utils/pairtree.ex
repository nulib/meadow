defmodule Meadow.Utils.Pairtree do
  @moduledoc """
  Functions for working with pairtrees
  """

  @doc """
  Generates a pyramid path

  ## Examples

    iex> Pairtree.generate_preservation_path("a13d45b1-69a6-447f-9d42-90b989a2949c", "412ca147684a67883226c644ee46b38460b787ec34e5b240983992af4a8c0a90")
    "a1/3d/45/b1/412ca147684a67883226c644ee46b38460b787ec34e5b240983992af4a8c0a90"

    iex> Pairtree.generate_preservation_path("a13d45b1-69a6-447f-9d42-90b989a2949c", "412ca147684a67883226c64")
    ** (ArgumentError) Invalid sha256 hash
  """
  def generate_preservation_path(id, sha256) when byte_size(sha256) == 64 do
    generate!(id, 4) <> "/" <> sha256
  end

  def generate_preservation_path(_, _) do
    raise ArgumentError, message: "Invalid sha256 hash"
  end

  @doc """
  Generate a pyramid path

  Examples:
    iex> Meadow.Utils.Pairtree.generate_pyramid_path("a13d45b1-69a6-447f-9d42-90b989a2949c")
    "a1/3d/45/b1/-6/9a/6-/44/7f/-9/d4/2-/90/b9/89/a2/94/9c-pyramid.tif"
  """
  def generate_pyramid_path(id) do
    generate!(id) <> "-pyramid.tif"
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
