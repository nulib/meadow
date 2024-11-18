defmodule Meadow.Config.Pipeline do
  @moduledoc """
  Configure Meadow Pipelines
  """

  defp get_config_value(action, var, default) do
    key = Module.split(action) |> List.last() |> Inflex.underscore() |> String.upcase()
    var_name = Enum.join([key, String.upcase(to_string(var))], "_")

    case System.get_env(var_name) do
      nil -> default
      val -> String.to_integer(val)
    end
  end

  def configure!(prefix) do
    prefix =
      case prefix do
        nil -> "meadow"
        "" -> "meadow"
        val -> val
      end

    config = Application.get_env(:meadow, Meadow.Pipeline)

    config =
      config
      |> Keyword.get(:actions)
      |> Enum.reduce(config, fn action, acc ->
        queue_name =
          [
            prefix
            | Module.split(action) |> List.last() |> Inflex.underscore() |> String.split("_")
          ]
          |> Enum.join("-")

        Keyword.put(acc, action,
          producer: [
            queue_name: queue_name,
            receive_interval: get_config_value(action, :receive_interval, 1000),
            wait_time_seconds: get_config_value(action, :wait_time_seconds, 1),
            max_number_of_messages: get_config_value(action, :max_number_of_messages, 10),
            visibility_timeout: get_config_value(action, :visibility_timeout, 300)
          ],
          processors: [
            default: [
              concurrency: get_config_value(action, :processor_concurrency, 10),
              max_demand: get_config_value(action, :max_demand, 10),
              min_demand: get_config_value(action, :min_demand, 5)
            ]
          ]
        )
      end)

    Application.put_env(:meadow, Meadow.Pipeline, config)
  end
end
