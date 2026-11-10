defmodule Meadow.Pipeline.Actions.EmbedImage do
  @moduledoc """
  Action to generate & store an image embedding for a FileSet

  The image is fetched from the IIIF server at the size the embedding model
  works at, so this action must run after the pyramid TIFF exists.

  Subscribes to:
  * CreatePyramidTiff

  """
  alias Meadow.Data.ActionStates
  alias Meadow.Embeddings
  alias Meadow.Embeddings.IIIFImage

  use Meadow.Pipeline.Actions.Common

  require Logger

  @error_message "error in image embedding"

  def actiondoc, do: "Generate image embedding for FileSet"

  def already_complete?(file_set, _) do
    file_set.id |> Embeddings.get_file_set_embedding() |> Embeddings.current_model?()
  end

  def process(file_set, _attributes) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    if Embeddings.enabled?() do
      file_set |> embed() |> handle_result(file_set)
    else
      Logger.info("Embeddings are disabled; skipping image embedding")
      handle_result({:ok, nil}, file_set)
    end
  end

  defp embed(file_set) do
    with {:ok, image} <- IIIFImage.fetch(file_set) do
      Embeddings.embed_file_set(file_set, image)
    end
  end

  def handle_result({:ok, _}, file_set) do
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    :ok
  end

  # The IIIF server can lag behind a freshly written pyramid, and it or the
  # network can fail transiently
  def handle_result({:error, {:http_error, status, message}}, _file_set)
      when status == 404 or status >= 500 do
    Logger.warning("HTTP error #{status}: #{inspect(message)}. Retrying.")
    :retry
  end

  def handle_result({:error, %{__exception__: true, __struct__: struct} = error}, _file_set)
      when struct in [Req.TransportError, Mint.TransportError] do
    Logger.warning("Transport error: #{Exception.message(error)}. Retrying.")
    :retry
  end

  def handle_result({:error, error}, file_set) do
    Logger.error("#{@error_message}: #{inspect(error)}")
    ActionStates.set_state!(file_set, __MODULE__, "error", @error_message)
    {:error, @error_message}
  end
end
