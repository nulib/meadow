defmodule Mix.Tasks.Meadow.OpenApiSpec do
  @moduledoc """
  Generates the OpenApi 3.0 spec
  Writes the JSON spec to an output file

    ## Examples

      iex> mix meadow.open_api_spec spec.json


  """
  def run([output_file]) do
    json =
      MeadowWeb.ApiSpec.spec()
      |> Jason.encode!(pretty: true)

    :ok = File.write!(output_file, json)
  end
end
