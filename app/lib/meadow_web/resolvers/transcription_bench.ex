defmodule MeadowWeb.Resolvers.TranscriptionBench do
  @moduledoc "Absinthe resolvers for the transcription bench."

  alias Meadow.TranscriptionBench
  alias Meadow.TranscriptionBench.{Models, Runner}

  def transcribable_file_sets(_root, args, _info) do
    {:ok, TranscriptionBench.list_transcribable_file_sets(Map.to_list(args))}
  end

  def models(_root, _args, _info), do: {:ok, Models.list()}

  def list_runs(_root, args, _info) do
    {:ok,
     TranscriptionBench.list_runs(
       limit: Map.get(args, :limit, 50),
       offset: Map.get(args, :offset, 0)
     )}
  end

  def get_run(_root, %{id: id}, _info) do
    case TranscriptionBench.get_run(id) do
      nil -> {:error, "Transcription run not found"}
      run -> {:ok, run}
    end
  end

  def start_run(_root, %{variants: variants} = args, %{context: %{current_user: user}})
      when is_list(variants) do
    args
    |> Map.put(:author, user.email)
    |> TranscriptionBench.create_run()
    |> case do
      {:ok, run} ->
        Runner.start(run.id)
        {:ok, TranscriptionBench.get_run(run.id)}

      {:error, message} when is_binary(message) ->
        {:error, message}

      {:error, other} ->
        {:error, inspect(other)}
    end
  end

  def start_run(_root, _args, _info), do: {:error, "variants must be a JSON array"}

  def retry_result(_root, %{id: id}, _info) do
    with {:ok, run_id} <- TranscriptionBench.retry_result(id) do
      Runner.start(run_id)
      {:ok, TranscriptionBench.get_run(run_id)}
    end
  end

  def cancel_result(_root, %{id: id}, _info) do
    with {:ok, run_id} <- TranscriptionBench.cancel_result(id) do
      {:ok, TranscriptionBench.get_run(run_id)}
    end
  end

  def cancel_run(_root, %{id: id}, _info) do
    with {:ok, run_id} <- TranscriptionBench.cancel_run(id),
         %{} = run <- TranscriptionBench.get_run(run_id) do
      {:ok, run}
    else
      nil -> {:error, "Transcription run not found"}
      error -> error
    end
  end

  def delete_run(_root, %{id: id}, _info) do
    case TranscriptionBench.delete_run(id) do
      {:ok, run} -> {:ok, run}
      {:error, message} when is_binary(message) -> {:error, message}
      {:error, other} -> {:error, inspect(other)}
    end
  end
end
