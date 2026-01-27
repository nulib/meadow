defmodule TraceFormatter do
  @moduledoc """
  An ExUnit formatter that logs the start and end of each test with a timestamp
  and the test's module and name to a file named `test_trace_seed_<seed>_<timestamp>.log`.
  The seed is taken from the ExUnit configuration to help correlate logs with test runs.
  """
  use GenServer

  def init(_opts) do
    seed = ExUnit.configuration()[:seed]
    log_file = File.open!("test_trace_seed_#{seed}_#{:os.system_time(:second)}.log", [:write, :utf8, :delayed_write])
    {:ok, %{log_file: log_file}}
  end

  def handle_cast({:test_started, %ExUnit.Test{} = test}, state) do
    log(state.log_file, "▶", "Starting", test)
    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{} = test}, state) do
    icon = case test.state do
      nil -> "✓"
      {:failed, _} -> "✗"
      {:skipped, _} -> "➟"
      {:invalid, _} -> "⚠"
    end
    log(state.log_file, icon, "Finished", test)
    {:noreply, state}
  end

  def handle_cast(_event, state), do: {:noreply, state}

  defp log(device, icon, message, test) do
    IO.puts(device, "[#{inspect(self())} #{DateTime.utc_now()}] #{icon} #{message}: #{test.module}.#{test.name}")
  end
end
