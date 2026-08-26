defmodule Mix.Tasks.Meadow.Pipeline.Setup do
  @moduledoc "Creates resources for the ingest pipeline"
  use Mix.Task

  alias Meadow.AWS.SQS
  alias Meadow.Pipeline

  require Logger

  @shortdoc @moduledoc
  def run(_) do
    if Meadow.Config.environment?(:prod) or not Meadow.Config.use_localstack?() do
      Logger.warning("Not in localstack environment – queue creation skipped")
    else
      [:aws_credentials, :req] |> Enum.each(&Application.ensure_all_started/1)

      Pipeline.children()
      |> Enum.each(fn {module, config} ->
        Logger.info("Creating Queue for #{module}")

        config
        |> get_in([:producer, :queue_name])
        |> SQS.create_queue!()
      end)
    end
  end
end

defmodule Mix.Tasks.Meadow.Pipeline.Purge do
  @moduledoc "Purges messages from all ingest pipeline queues"
  use Mix.Task

  alias Meadow.AWS.SQS
  alias Meadow.Pipeline
  alias Meadow.Pipeline.Action

  require Logger

  @shortdoc @moduledoc
  def run(_) do
    [:aws_credentials, :req] |> Enum.each(&Application.ensure_all_started/1)

    Pipeline.children()
    |> Enum.each(fn {module, _} ->
      Logger.info("Purging Queue for #{module}")

      module
      |> Action.queue_url()
      |> SQS.purge_queue!()
    end)
  end
end
