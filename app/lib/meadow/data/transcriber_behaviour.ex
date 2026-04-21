defmodule Meadow.Data.TranscriberBehaviour do
  @moduledoc """
  Contract for an AI transcription backend used by `Meadow.Data.FileSets`.

  Implementations invoke a model (e.g. AWS Bedrock) and return the transcribed
  text plus detected languages.
  """

  @type success :: %{
          text: binary(),
          languages: [binary()],
          raw: map(),
          streamed_chunks: list()
        }

  @doc """
  Transcribe the representative image for the given file set id.

  Returns `{:ok, t:success/0}` on success, or `{:error, reason}` when the
  request cannot be completed.
  """
  @callback transcribe(file_set_id :: binary(), opts :: keyword()) ::
              {:ok, success()} | {:error, term()}
end
