defmodule Meadow.Embeddings.Config do
  @moduledoc """
  Convenience functions for retrieving embedding configuration
  """

  @doc "Whether Meadow generates embeddings at all"
  def enabled?, do: get(:enabled, false)

  @doc "The module implementing `Meadow.Embeddings.Model`"
  def model, do: get(:model, Meadow.Embeddings.Model.ONNX)

  @doc "The model name recorded with every stored vector and indexed as `embedding_model`"
  def model_name, do: get(:model_name)

  @doc "The Hugging Face repository the ONNX model is downloaded from"
  def repository, do: get(:repository)

  @doc "The repository revision (branch, tag or commit) to download"
  def revision, do: get(:revision, "main")

  @doc "The ONNX file variant under `onnx/`, without extension (e.g. `model`)"
  def variant, do: get(:variant, "model")

  @doc "The directory model files are cached in"
  def model_dir, do: get(:model_dir)

  @doc "Whether missing model files are downloaded on first use"
  def auto_download?, do: get(:auto_download, true)

  @doc "The size of the vectors the model produces"
  def dimensions, do: get(:dimensions, 768)

  @doc "The maximum number of tokens per input; longer inputs are truncated"
  def max_tokens, do: get(:max_tokens, 2048)

  @doc "The maximum length of the embedding text, in bytes"
  def max_text_length, do: get(:max_text_length, 2048)

  @doc """
  The soft token budget per image (70, 140, 280, 560 or 1120). More tokens
  preserve more detail at the cost of slower inference.
  """
  def image_soft_tokens, do: get(:image_soft_tokens, 280)

  @doc "The number of inputs per inference run"
  def batch_size, do: get(:batch_size, 8)

  @doc "The index document fields that make up a work's embedding text, in order"
  def text_fields, do: get(:text_fields, [])

  @doc "Extra `Req` options for model downloads and IIIF image requests"
  def req_options, do: get(:req_options, [])

  defp get(key, default \\ nil) do
    :meadow
    |> Application.get_env(Meadow.Embeddings, [])
    |> Keyword.get(key, default)
  end
end
