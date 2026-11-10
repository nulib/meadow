defmodule Meadow.Embeddings.Model do
  @moduledoc """
  Behaviour for text embedding models. Implementations receive complete
  prompts (see `Meadow.Embeddings.Prompt`) and return one L2-normalized
  vector per prompt, in order.
  """

  @callback embed(prompts :: [String.t()]) :: {:ok, [[float()]]} | {:error, term()}

  @doc """
  Embed one encoded image (JPEG, PNG, TIFF, ...). Images take no prompt and
  share the embedding space with text, so the vector can be compared with
  query and document vectors alike.
  """
  @callback embed_image(image :: binary()) :: {:ok, [float()]} | {:error, term()}
end
