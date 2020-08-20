defmodule Meadow.Utils.ArkClient.MockServer do
  @moduledoc """
  Mock EZID API server for testing Meadow.Ark

  Mints and stores ARKs using a naive format of:

      shoulder + number of milliseconds since 2020-06-01T00:00:00 padded to 8 digits]

  Backed by an ETS store, so ARK metadata is cleared every time the server is stopped.

  Also has the ability to send inter-process messages in order to make testing
  easier.
  """

  use Plug.Router
  plug :match
  plug :dispatch

  @cache Meadow.Utils.ArkClient.MockServer.Cache
  @epoch ~N[2020-06-01 00:00:00]

  @doc """
  Specify a process to send messages to about requests. Good for testing
  request serialization.
  """
  def send_to(nil) do
    Cachex.del!(@cache, :send_to)
    :ok
  end

  def send_to(target) when is_pid(target) do
    Cachex.put!(@cache, :send_to, target)
    :ok
  end

  def send_to(target) do
    {:error, "#{target} is not a valid message recipient"}
  end

  get "/id/*stem" do
    ark = Enum.join(stem, "/")

    send_message({:get, :ark, ark})
    send_message({:get, :credentials, Plug.BasicAuth.parse_basic_auth(conn)})

    case Cachex.get!(@cache, ark) do
      nil -> send_resp(conn, 404, "error: bad request - no such identifier")
      data -> send_resp(conn, 200, "success: #{ark}\n#{data}")
    end
  end

  post "/shoulder/*stem" do
    shoulder = Enum.join(stem, "/")

    ark = shoulder <> timestamp()

    {:ok, body, _} = Plug.Conn.read_body(conn)

    send_message({:post, :shoulder, shoulder})
    send_message({:post, :credentials, Plug.BasicAuth.parse_basic_auth(conn)})
    send_message({:post, :body, body})

    Cachex.put!(@cache, ark, body)
    send_resp(conn, 201, "success: #{ark}")
  end

  put "/id/*stem" do
    ark = Enum.join(stem, "/")
    {:ok, body, _} = Plug.Conn.read_body(conn)

    send_message({:put, :ark, ark})
    send_message({:put, :credentials, Plug.BasicAuth.parse_basic_auth(conn)})
    send_message({:put, :body, body})

    Cachex.put!(@cache, ark, body)
    send_resp(conn, 200, "success: #{ark}\n#{body}")
  end

  defp send_message(message) do
    case Cachex.get!(@cache, :send_to) do
      nil -> :noop
      process -> send(process, message)
    end
  end

  defp timestamp do
    now =
      NaiveDateTime.local_now()
      |> NaiveDateTime.truncate(:millisecond)
      |> NaiveDateTime.diff(@epoch, :millisecond)

    Kernel.trunc(now / 1000)
    |> Integer.to_string()
    |> String.pad_leading(8, "0")
  end
end
