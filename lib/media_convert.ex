defmodule MediaConvert do
  @moduledoc """
  Provides functionality for the AWS Elemental MediaConvert API
  """

  alias ExAws.Operation.JSON, as: Operation

  @doc """
  Configure ExAws to use the MediaConvert Endpoint provided by AWS
  """
  def configure! do
    with endpoint <- get_endpoint() |> URI.parse() do
      Application.put_env(:ex_aws, :mediaconvert,
        host: endpoint.host,
        scheme: endpoint.scheme,
        port: endpoint.port
      )
    end
  end

  @doc """
  Send a :post request to create a MediaConvert job via the MediaConvert HTTP API
  """
  def create_job(template) do
    if Application.get_env(:ex_aws, :mediaconvert) |> is_nil(), do: configure!()

    case request(:post, "jobs", template) |> ExAws.request() do
      {:ok, response} -> {:ok, get_in(response, ["job", "id"])}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_endpoint do
    case request(:post, "endpoints") |> ExAws.request() do
      {:ok, response} -> get_in(response, ["endpoints", Access.at(0), "url"])
      {:error, reason} -> {:error, reason}
    end
  end

  defp request(http_method, path, data \\ %{}) do
    Operation.new(:mediaconvert, %{
      data: data,
      headers: [{"content-type", "application/json"}],
      http_method: http_method,
      path: "/2017-08-29/#{path}",
      service: :mediaconvert
    })
  end
end
