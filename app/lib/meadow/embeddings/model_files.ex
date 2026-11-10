defmodule Meadow.Embeddings.ModelFiles do
  @moduledoc """
  Locates the ONNX model and tokenizer on disk, downloading them from the
  Hugging Face Hub when they are missing.

  Files are cached under `model_dir/repository/revision`, mirroring the
  repository layout. The ONNX graph keeps its weights in an external
  `.onnx_data` file that must sit next to it.
  """

  alias Meadow.Embeddings.Config

  require Logger

  @hub "https://huggingface.co"

  @doc "The directory holding the files for the configured model"
  def dir, do: Path.join([Config.model_dir(), Config.repository(), Config.revision()])

  @doc "Path to the ONNX graph of the text and multimodal model"
  def model_path, do: Path.join(dir(), "onnx/#{Config.variant()}.onnx")

  @doc "Path to the ONNX graph of the vision encoder"
  def vision_model_path, do: Path.join(dir(), "onnx/vision_encoder.onnx")

  @doc "Path to the tokenizer definition"
  def tokenizer_path, do: Path.join(dir(), "tokenizer.json")

  @doc """
  Repository-relative paths of the files a component needs. `:text` is the
  tokenizer and the main model; `:vision` is the image encoder that feeds it.
  """
  def files(component \\ :text)

  def files(:text) do
    ["tokenizer.json", "onnx/#{Config.variant()}.onnx", "onnx/#{Config.variant()}.onnx_data"]
  end

  def files(:vision), do: ["onnx/vision_encoder.onnx", "onnx/vision_encoder.onnx_data"]

  @doc "Whether every file of a component is present"
  def available?(component \\ :text),
    do: Enum.all?(files(component), &File.exists?(Path.join(dir(), &1)))

  @doc """
  Make sure a component's files are on disk, downloading any that are
  missing unless `auto_download` is disabled.
  """
  @spec ensure(:text | :vision) :: :ok | {:error, term()}
  def ensure(component \\ :text) do
    cond do
      available?(component) -> :ok
      Config.auto_download?() -> download(component)
      true -> {:error, {:model_files_missing, dir()}}
    end
  end

  @doc "Download a component's missing files"
  @spec download(:text | :vision) :: :ok | {:error, term()}
  def download(component \\ :text) do
    files(component)
    |> Enum.reject(&File.exists?(Path.join(dir(), &1)))
    |> Enum.reduce_while(:ok, fn file, :ok ->
      case fetch(file) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp fetch(file) do
    url = Enum.join([@hub, Config.repository(), "resolve", Config.revision(), file], "/")
    target = Path.join(dir(), file)
    partial = target <> ".part"
    File.mkdir_p!(Path.dirname(target))
    Logger.info("Downloading #{url}")

    options =
      [url: url, into: File.stream!(partial), decode_body: false, receive_timeout: 120_000]
      |> Keyword.merge(Config.req_options())

    case Req.get(options) do
      {:ok, %{status: 200}} ->
        File.rename(partial, target)

      {:ok, %{status: status}} ->
        File.rm(partial)
        {:error, {:download_failed, url, status}}

      {:error, reason} ->
        File.rm(partial)
        {:error, {:download_failed, url, reason}}
    end
  end
end
