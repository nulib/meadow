defmodule Meadow.Utils.MIME do
  @moduledoc """
  MIME type helpers that go slightly beyond the functionality
  provided by the MIME package
  """

  alias Elixir.MIME, as: MimeTypes

  @doc """
  Determine the MIME type from a pathname

  Examples:
    iex> MIME.from_path("/path/to/image.tiff")
    "image/tiff"

    iex> MIME.from_path("/path/to/image.framemd5")
    "text/plain"

    iex> MIME.from_path("/path/to/unknown.blorb")
    "application/octet-stream"
  """
  def from_path(path) do
    with "." <> ext <- path |> Path.extname() do
      type(ext)
    end
  end

  @doc """
  Determine the MIME type from a file extension

  Examples:
  iex> MIME.type("tiff")
  "image/tiff"

  iex> MIME.type("framemd5")
  "text/plain"

  iex> MIME.type("blorb")
  "application/octet-stream"
  """
  def type(ext) do
    Application.get_env(:meadow, :extra_mime_types)
    |> Map.get(to_string(ext), MimeTypes.type(ext))
  end
end
