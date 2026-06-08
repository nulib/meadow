defmodule MeadowWeb.RemoteAccessTest do
  use ExUnit.Case, async: true

  alias MeadowWeb.RemoteAccess

  defp serve(sock, response, caller) do
    case :gen_tcp.accept(sock) do
      {:ok, conn} ->
        {:ok, data} = :gen_tcp.recv(conn, 0)
        send(caller, {:socket_request, data})
        :gen_tcp.send(conn, response)
        :gen_tcp.close(conn)
        serve(sock, response, caller)

      {:error, :closed} ->
        :ok
    end
  end

  describe "url/1" do
    setup tags do
      if response = tags[:socket_response] do
        socket_path = Path.join(System.tmp_dir!(), "test-#{System.unique_integer()}.sock")
        on_exit(fn -> File.rm(socket_path) end)

        {:ok, listen_sock} =
          :gen_tcp.listen(0, [:binary, packet: :raw, active: false, ifaddr: {:local, socket_path}])

        reply =
          [
            "HTTP/1.1 200 OK",
            "Content-Length: #{byte_size(response)}",
            "Content-Type: application/json",
            "",
            response
          ]
          |> Enum.join("\n")

        caller = self()
        Task.start(fn -> serve(listen_sock, reply, caller) end)
        System.put_env("TS_SOCKET", socket_path)
        on_exit(fn ->
          :gen_tcp.close(listen_sock)
          System.delete_env("TS_SOCKET")
        end)
      end

      :ok
    end

    @tag socket_response: File.read!("test/fixtures/remote_access/complex_funnel.json")
    test "returns the funnel URL if a funnel is active" do
      assert RemoteAccess.url() == "https://my.tailnet:3333"
      assert RemoteAccess.url("api/mcp") == "https://my.tailnet:3333/api/mcp"
      assert_receive {:socket_request, "GET /localapi/v0/serve-config" <> _}
    end

    @tag socket_response: File.read!("test/fixtures/remote_access/funnel_with_path.json")
    test "returns the funnel URL if the funnel is mounted on a path" do
      assert RemoteAccess.url() == "https://my.tailnet/meadow"
      assert RemoteAccess.url("api/mcp") == "https://my.tailnet/meadow/api/mcp"
      assert_receive {:socket_request, "GET /localapi/v0/serve-config" <> _}
    end

    @tag socket_response: "{}"
    test "returns the local server URL if no funnel is active" do
      assert RemoteAccess.url() == "http://localhost:4002"
      assert RemoteAccess.url("api/mcp") == "http://localhost:4002/api/mcp"
      assert_receive {:socket_request, "GET /localapi/v0/serve-config" <> _}
    end

    test "returns the local server URL if the CLI command fails" do
      assert RemoteAccess.url() == "http://localhost:4002"
      assert RemoteAccess.url("api/mcp") == "http://localhost:4002/api/mcp"
      refute_receive {:socket_request, "GET /localapi/v0/serve-config" <> _}
    end
  end
end
