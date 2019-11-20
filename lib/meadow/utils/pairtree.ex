defmodule Meadow.Utils.Pairtree do
  @moduledoc """
  Functions for working with pairtrees
  """

  @doc """
  Generate a pairtree

  Examples:
    Meadow.Utils.Pairtree.generate("abcdef")
    => "ab/cd/ef/abcdef"

    Meadow.Utils.Pairtree.generate("abcdef", 2)
    => "ab/cd/abcdef"
  """
  def generate(id, length \\ nil) do
    transform = fn str ->
      (Regex.scan(~r/../, str) ++ [id])
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
  """
  def generate!(id, length \\ nil) do
    case generate(id, length) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc """
  Generate a pairtree for a pyramid key

  Example:
    Meadow.Utils.Pairtree.generate_pyramid_path("01DT5BNAR8XB6YFWB9V1VQQKDN")
    => "01/dt/5b/na/r8/xb/6y/fw/b9/v1/vq/qk/dn-pyramid.tif"
  """
  def generate_pyramid_path(id) do
    transform = fn str ->
      (Regex.scan(~r/../, String.slice(str, 0, 24)) ++
         ["#{String.slice(str, 24, 2)}-pyramid.tif"])
      |> Enum.join("/")
      |> String.downcase()
    end

    id |> String.slice(0, 26 * 2) |> transform.()
  end
end
