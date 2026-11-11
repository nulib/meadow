defmodule Meadow.TranscriptionBench.Runner do
  @moduledoc """
  Transcribes the queued results of a bench run in a supervised background task, a few
  at a time, so that the request that started the run returns at once.
  """

  alias Meadow.TranscriptionBench
  alias Meadow.TranscriptionBench.{Client, Result}

  require Logger

  @concurrency 4

  @doc """
  Transcribe whatever is queued in a run. Safe to call again while a run is under way
  (a retry does): each result is claimed before it is sent, so none is sent twice.
  """
  def start(run_id) do
    Task.Supervisor.start_child(
      Meadow.TranscriptionBench.TaskSupervisor,
      fn -> execute(run_id) end,
      restart: :temporary
    )
  end

  @doc false
  def execute(run_id, client \\ Client) do
    case TranscriptionBench.get_run(run_id) do
      nil ->
        :ok

      run ->
        variants = Map.new(run.variants, &{&1["id"], &1})

        # Not linked: a cancelled result's task is killed, and the others carry on.
        Meadow.TranscriptionBench.TaskSupervisor
        |> Task.Supervisor.async_stream_nolink(
          TranscriptionBench.queued_results(run_id),
          &transcribe(&1, Map.get(variants, &1.variant_id), client),
          max_concurrency: @concurrency,
          timeout: :infinity
        )
        |> Stream.run()
    end
  end

  @doc false
  def transcribe(%Result{} = result, variant, client \\ Client) do
    if TranscriptionBench.claim_result(result) do
      # Where TranscriptionBench.cancel_result/1 finds this process, to kill it.
      Horde.Registry.register(
        Meadow.HordeRegistry,
        TranscriptionBench.transcribing_key(result.id),
        nil
      )

      started = System.monotonic_time(:millisecond)

      outcome =
        try do
          attempt(result, variant, client)
        rescue
          error ->
            Logger.error("Bench transcription #{result.id} failed: #{Exception.message(error)}")
            %{status: "error", error: Exception.message(error)}
        end

      duration = System.monotonic_time(:millisecond) - started
      TranscriptionBench.finish_result(result, Map.put(outcome, :duration_ms, duration))
    end

    :ok
  end

  defp attempt(_result, nil, _client),
    do: %{status: "error", error: "The run no longer has this result's variant"}

  defp attempt(result, variant, client) do
    with {:ok, image} <- client.fetch_image(result.image_url, variant, result.model),
         {:ok, body} <- client.request_body(variant, image) do
      sent = sent_fields(image)

      case client.converse(result.model, body) do
        {:ok, out} ->
          Map.merge(sent, %{
            status: "done",
            request: client.redact(body, result.model),
            tool_input: out.tool_input,
            text: out.text,
            reasoning: out.reasoning,
            stop_reason: out.stop_reason,
            usage: out.usage
          })

        {:error, message} ->
          Map.merge(sent, %{
            status: "error",
            error: message,
            request: client.redact(body, result.model)
          })
      end
    else
      {:error, message} -> %{status: "error", error: message}
    end
  end

  defp sent_fields(
         %{bytes: bytes, sent: {sent_width, sent_height}, full: {width, height}} = image
       ) do
    {processed_width, processed_height} = Map.get(image, :processed, image.sent)

    %{
      processed_width: processed_width,
      processed_height: processed_height,
      sent_width: sent_width,
      sent_height: sent_height,
      sent_bytes: byte_size(bytes),
      image_width: width,
      image_height: height
    }
  end
end
