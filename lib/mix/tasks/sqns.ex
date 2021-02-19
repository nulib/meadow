defmodule Mix.Tasks.Meadow.Pipeline.Setup do
  @moduledoc "Creates resources for the ingest pipeline"
  alias Meadow.Pipeline
  use Mix.Task

  @shortdoc @moduledoc
  def run(_) do
    [:ex_aws, :hackney] |> Enum.each(&Application.ensure_all_started/1)
    Pipeline.queue_config() |> Sequins.setup()
  end
end

defmodule Mix.Tasks.Meadow.Pipeline.Purge do
  @moduledoc "Purges messages from all ingest pipeline queues"
  alias Meadow.Pipeline
  use Mix.Task

  require Logger

  @shortdoc @moduledoc
  def run(_) do
    [:ex_aws, :hackney] |> Enum.each(&Application.ensure_all_started/1)

    Pipeline.queue_config()
    |> Sequins.parse_queues()
    |> Enum.each(fn queue ->
      Logger.info("Purging queue: #{queue}")

      case ExAws.SQS.get_queue_url(queue) |> ExAws.request() do
        {:ok, result} ->
          result
          |> get_in([:body, :queue_url])
          |> ExAws.SQS.purge_queue()
          |> ExAws.request!()

        {:error, _} ->
          Logger.warn("Queue #{queue} doesn't exist")
      end
    end)
  end
end
