defmodule Meadow.Data.TranscriberBehaviour do
  @moduledoc """
  Contract for an AI transcription backend used by `Meadow.Data.FileSets`.

  Implementations invoke a model (e.g. AWS Bedrock) and return the transcribed
  text plus detected languages. Swapped at runtime via `:meadow, :transcriber`
  so tests can supply a Mox mock.
  """

  @type t :: %{
          text: String.t(),
          languages: [String.t()],
          raw: map(),
          streamed_chunks: list()
        }

  @doc """
  Transcribe the representative image for the given file set id.

  Returns `{:ok, t:t/0}` on success, or `{:error, reason}` when the request
  cannot be completed.
  """
  @callback transcribe(file_set_id :: String.t(), opts :: keyword()) ::
              {:ok, t()} | {:error, term()}
end
