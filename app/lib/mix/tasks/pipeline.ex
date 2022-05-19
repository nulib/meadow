defmodule Mix.Tasks.Meadow.Pipeline.Setup do
  @moduledoc "Creates resources for the ingest pipeline"
  use Mix.Task

  alias Meadow.Pipeline

  require Logger

  @shortdoc @moduledoc
  def run(_) do
    [:ex_aws, :hackney] |> Enum.each(&Application.ensure_all_started/1)

    Pipeline.children()
    |> Enum.each(fn {module, config} ->
      Logger.info("Creating Queue for #{module}")

      config
      |> get_in([:producer, :queue_name])
      |> ExAws.SQS.create_queue()
      |> ExAws.request!()
    end)
  end
end

defmodule Mix.Tasks.Meadow.Pipeline.Purge do
  @moduledoc "Purges messages from all ingest pipeline queues"
  use Mix.Task

  alias Meadow.Pipeline
  alias Meadow.Pipeline.Action

  require Logger

  @shortdoc @moduledoc
  def run(_) do
    [:ex_aws, :hackney] |> Enum.each(&Application.ensure_all_started/1)

    Pipeline.children()
    |> Enum.each(fn {module, _} ->
      Logger.info("Purging Queue for #{module}")

      module
      |> Action.queue_url()
      |> ExAws.SQS.purge_queue()
      |> ExAws.request!()
    end)
  end
end
