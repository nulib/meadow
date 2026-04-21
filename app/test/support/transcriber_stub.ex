defmodule Meadow.Data.TranscriberStub do
  @moduledoc """
  Test fallback transcriber used when a test opts into the mock without
  providing a specific expectation.
  """

  @behaviour Meadow.Data.TranscriberBehaviour

  @impl true
  def transcribe(_file_set_id, _opts) do
    {:error, :transcriber_not_mocked}
  end
end
