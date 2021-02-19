defmodule RequireHttpsTest do
  use MeadowWeb.ConnCase, async: false

  alias MeadowWeb.Plugs.RequireHttps

  describe "RequireHttps" do
    setup do
      with old_config <- Application.get_env(:meadow, MeadowWeb.Endpoint),
           new_config <- old_config |> Keyword.put(:https, port: 4003) do
        Application.put_env(:meadow, MeadowWeb.Endpoint, new_config)
        Application.stop(:meadow)
        Application.ensure_all_started(:meadow)

        on_exit(fn ->
          Application.put_env(:meadow, MeadowWeb.Endpoint, old_config)
          Application.stop(:meadow)
          Application.ensure_all_started(:meadow)
        end)
      end
    end

    test "redirects to secure version when possible" do
      conn =
        build_conn()
        |> RequireHttps.call(%{})

      assert conn.status == 302
      assert conn.resp_headers |> Enum.member?({"location", "https://www.example.com:4003/"})
    end

    test "passes through when current connection is secure" do
      conn =
        build_conn()
        |> Map.put(:scheme, :https)
        |> RequireHttps.call(%{})

      assert conn.status |> is_nil()
    end
  end

  test "passes through when no secure config exists" do
    conn =
      build_conn()
      |> RequireHttps.call(%{})

    assert conn.status |> is_nil()
  end
end
