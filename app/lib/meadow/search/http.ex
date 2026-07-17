defmodule Meadow.Search.HTTP do
  @moduledoc """
  Meadow config-aware Req client for the OpenSearch cluster
  """
  alias Meadow.Error
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Utils.AWS

  use Meadow.HTTP.Base

  @max_retries 10

  def preprocess_opts(opts) do
    opts
    |> put_new_header("content-type", "application/json")
    |> Keyword.put_new(:base_url, SearchConfig.cluster_url())
    |> Keyword.put_new(:retry, :transient)
    |> Keyword.put_new(:max_retries, @max_retries)
    |> Keyword.put_new(:retry_delay, &retry_delay/1)
    |> Keyword.put_new(:aws_sigv4, {AWS, :aws_sigv4_options, [:es]})
  end

  def attach_steps(request) do
    Req.Request.append_error_steps(request, meadow_report_error: &report_error/1)
  end

  defp report_error({request, exception}) do
    Error.report(exception, __MODULE__, [], %{
      method: request.method,
      url: URI.to_string(request.url)
    })

    {request, exception}
  end

  defp retry_delay(retry_count) do
    (10 * :math.pow(2, retry_count))
    |> min(1_000)
    |> Kernel.*(0.5 + :rand.uniform())
    |> round()
  end

  defp put_new_header(opts, name, value) do
    headers = Keyword.get(opts, :headers, [])

    if List.keymember?(headers, name, 0) do
      opts
    else
      Keyword.put(opts, :headers, [{name, value} | headers])
    end
  end
end
