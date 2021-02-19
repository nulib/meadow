defmodule Meadow.Async do
  @moduledoc """
  Performs singleton tasks asynchronously using Elixir's built-in Registry
  """

  @environment Mix.env()

  def run_once(task_id, fun) do
    run_once(task_id, fun, @environment)
  end

  def run_once(task_id, fun, :test) do
    send(self(), {task_id, fun.()})
    {:sync, self()}
  end

  def run_once(task_id, fun, _env) do
    case Meadow.TaskRegistry |> Registry.lookup(task_id) do
      [{pid, _}] ->
        {:running, pid}

      _ ->
        receiver = self()

        Task.start(fn ->
          try do
            Meadow.TaskRegistry |> Registry.register(task_id, nil)
            send(receiver, {task_id, fun.()})
          after
            Meadow.TaskRegistry |> Registry.unregister(task_id)
          end
        end)
    end
  end
end
