defmodule Mix.Tasks.Meadow.Pipeline.Setup do
  @moduledoc "Creates resources for the ingest pipeline"
  use Mix.Task

  @shortdoc @moduledoc
  def run(_) do
    [:ex_aws, :hackney] |> Enum.each(&Application.ensure_all_started/1)

    case Application.get_env(:meadow, Meadow.Ingest.Pipeline, []) |> Keyword.get(:queues) do
      nil -> raise "Pipeline configuration not found"
      specs -> specs |> SQNS.setup()
    end
  end
end
