defmodule Meadow.Utils.AWS do
  @moduledoc """
  Utility functions for AWS requests
  """

  def add_aws_signature(request, region, access_key, secret) do
    request.headers ++ generate_aws_signature(request, region, access_key, secret)
  end

  defp generate_aws_signature(request, region, access_key, secret) do
    signed_request =
      Sigaws.sign_req(
        request.url,
        method: request.method |> to_string() |> String.upcase(),
        headers: request.headers,
        body: request.body,
        service: "es",
        region: region,
        access_key: access_key,
        secret: secret
      )

    case signed_request do
      {:ok, headers, _} -> headers |> Enum.into([])
      other -> other
    end
  end
end
