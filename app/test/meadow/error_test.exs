defmodule Meadow.ErrorTest do
  use Honeybadger.Case
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: true

  use Meadow.Utils.Logging

  alias Meadow.Config
  alias Plug.Conn.Cookies

  import Plug.Conn

  @cookie "dcApiToken=PLEASE_REDACT; dcApiUser=PLEASE_REDACT; amlbcookie=01; nusso=PLEASE_REDACT; _meadow_key=PLEASE_REDACT; PS_DEVICEFEATURES=width:2560 height:1440 pixelratio:1 touch:0 geolocation:1 websockets:1 webworkers:1 datepicker:0 dtpicker:0 timepicker:0 dnd:1 sessionstorage:1 localstorage:1 history:1 canvas:1 svg:1 postmessage:1 hc:0 maf:0"
  @expect_redacted ~w(dcApiToken dcApiUser nusso _meadow_key)
  @expect_unredacted ~w(amlbcookie PS_DEVICEFEATURES)

  setup do
    {:ok, _} = Honeybadger.API.start(self())

    on_exit(&Honeybadger.API.stop/0)
  end

  describe "report/4" do
    test "sends error notifications" do
      restart_with_config(exclude_envs: [])

      bad_function = fn denominator ->
        with_log_metadata module: __MODULE__, id: 107 do
          try do
            107 / denominator
          rescue
            exception ->
              Meadow.Error.report(exception, __MODULE__, __STACKTRACE__, %{extra_data: "foo"})
          end
        end
      end

      bad_function.(0)
      assert_receive {:api_request, report}, 2500

      with request_context <- report |> get_in(["request", "context"]) do
        assert request_context |> Map.get("extra_data") == "foo"
        assert request_context |> Map.get("meadow_version") == Config.meadow_version()
        assert request_context |> Map.get("notifier") == __MODULE__ |> to_string()
      end
    end
  end

  describe "phoenix error" do
    test "sends error notifications" do
      restart_with_config(exclude_envs: [])

      user = user_fixture(:administrator)

      conn =
        build_conn()
        |> auth_user(user)
        |> put_req_header("cookie", @cookie)
        |> put_req_header("content-type", "application/json")

      assert_raise Ecto.Query.CastError, fn ->
        post(
          conn,
          "/api/graphql",
          ~s'{"query":"query{ work(id:\\"this-is-not-a-uuid\\"){ id } }","variables":null}'
        )
      end

      assert_receive {:api_request, report}, 1000

      with cookies <- report |> get_in(["request", "cgi_data", "HTTP_COOKIE"]) |> Cookies.decode() do
        (@expect_redacted ++ @expect_unredacted)
        |> Enum.each(fn key -> assert cookies |> Map.has_key?(key) end)

        @expect_redacted
        |> Enum.each(fn key -> assert cookies |> Map.get(key) == "[REDACTED]" end)

        @expect_unredacted
        |> Enum.each(fn key -> refute cookies |> Map.get(key) == "[REDACTED]" end)
      end
    end
  end
end
