defmodule Mix.Tasks.Meadow.OpenApiSpec do
  @moduledoc """
  Generates the OpenApi 3.0 spec
  Writes the JSON spec to stdout or an output file

    ## Examples
      $ mix meadow.open_api_spec
      $ mix meadow.open_api_spec spec.json
  """
  def run([]) do
    IO.puts(json_spec())
  end

  def run([output_file]) do
    :ok = File.write!(output_file, json_spec())
  end

  defp json_spec do
    MeadowWeb.ApiSpec.spec()
    |> Jason.encode!(pretty: true)
  end
end
