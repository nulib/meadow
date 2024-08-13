defmodule Meadow.ML.Inference do
  require Logger

  @aws_region "us-east-1"
  @max_string_length 2048
  @max_strings 96
  @model "cohere.embed-multilingual-v3"

  def get_embeddings(strings) do
    strings
    |> Enum.map(&String.slice(&1, 0, @max_string_length - 1))
    |> Enum.chunk_every(@max_strings)
    |> Enum.flat_map(fn chunk ->
      embed(chunk)
    end)
    |> Nx.tensor()
    |> Nx.to_list()
  end

  def embed(strings) do
    operation = %ExAws.Operation.RestQuery{
      action: :invoke_model,
      body: %{texts: strings, input_type: "classification"},
      http_method: :post,
      path: "/model/#{@model}/invoke",
      service: :bedrock
    }

    case ExAws.request(operation,
           host: ExAws.Config.Defaults.host("bedrock-runtime", @aws_region),
           headers: [{"Content-Type", "application/json"}, {"Accept", "*/*"}]
         ) do
      {:ok, %{body: body}} ->
        Jason.decode!(body)
        |> Map.get("embeddings")

      {status, response} ->
        Logger.warning("Embedding returned #{status}: #{inspect(response)}")
        []
    end
  end
end
