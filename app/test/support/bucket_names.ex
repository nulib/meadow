defmodule Meadow.BucketNames do
  @moduledoc """
  Import all bucket names as attributes into the using module
  """

  defmacro __using__(_) do
    quote do
      with prefixed <- fn name ->
             [Meadow.Config.Secrets.prefix(), name]
             |> Enum.reject(&is_nil/1)
             |> Enum.join("-")
           end do
        @ingest_bucket prefixed.("ingest")
        @preservation_bucket prefixed.("preservation")
        @preservation_check_bucket prefixed.("preservation-checks")
        @upload_bucket prefixed.("upload")
        @pyramid_bucket prefixed.("pyramids")
        @streaming_bucket prefixed.("streaming")
      end
    end
  end
end
