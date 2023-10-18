defmodule Honeybadger.Case do
  @moduledoc """
  Case template for capturing and testing Honeybadger notifications.
  Copied with minor changes from https://github.com/honeybadger-io/honeybadger-elixir/blob/master/test/test_helper.exs
  """
  use ExUnit.CaseTemplate

  using(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  def restart_with_config(opts) do
    :ok = Application.stop(:honeybadger)
    original = take_original_env(opts)

    put_all_env(opts)

    on_exit(fn ->
      :ok = Application.stop(:honeybadger)
      put_all_env(original)
      :ok = Application.ensure_started(:honeybadger)
    end)

    :ok = Application.ensure_started(:honeybadger)
  end

  defp take_original_env(opts) do
    Keyword.take(Application.get_all_env(:honeybadger), Keyword.keys(opts))
  end

  defp put_all_env(opts) do
    Enum.each(opts, fn {key, val} ->
      Application.put_env(:honeybadger, key, val)
    end)
  end
end

defmodule Honeybadger.API do
  @moduledoc """
  Mock API for Honeybadger testing
  """
  import Plug.Conn

  alias Plug.Cowboy
  alias Plug.Conn

  def start(pid) do
    Cowboy.http(__MODULE__, [test: pid], port: 4444)
  end

  def stop do
    :timer.sleep(100)
    Cowboy.shutdown(__MODULE__.HTTP)
    :timer.sleep(100)
  end

  def init(opts) do
    Keyword.fetch!(opts, :test)
  end

  def call(%Conn{method: "POST"} = conn, test) do
    {:ok, body, conn} = read_body(conn)

    send(test, {:api_request, Jason.decode!(body)})

    send_resp(conn, 200, "{}")
  end

  def call(conn, _test) do
    send_resp(conn, 404, "Not Found")
  end
end
