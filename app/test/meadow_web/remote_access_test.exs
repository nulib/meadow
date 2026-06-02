defmodule MeadowWeb.RemoteAccessTest do
  use ExUnit.Case, async: true

  alias MeadowWeb.RemoteAccess

  describe "url/1" do
    setup tags do
      Application.put_env(:meadow, :system_cmd, {__MODULE__, tags[:cmd_function]})
      on_exit(fn -> Application.delete_env(:meadow, :system_cmd) end)
    end

    @tag cmd_function: :mock_system_cmd_complex
    test "returns the funnel URL if a funnel is active" do
      assert RemoteAccess.url() == "https://my.tailnet:3333"
      assert RemoteAccess.url("api/mcp") == "https://my.tailnet:3333/api/mcp"
    end

    @tag cmd_function: :mock_system_cmd_with_path
    test "returns the funnel URL if the funnel is mounted on a path" do
      assert RemoteAccess.url() == "https://my.tailnet/meadow"
      assert RemoteAccess.url("api/mcp") == "https://my.tailnet/meadow/api/mcp"
    end

    @tag cmd_function: :mock_system_cmd_no_funnel
    test "returns the local server URL if no funnel is active" do
      assert RemoteAccess.url() == "http://localhost:4002"
      assert RemoteAccess.url("api/mcp") == "http://localhost:4002/api/mcp"
    end

    @tag cmd_function: :mock_system_cmd_failure
    test "returns the local server URL if the CLI command fails" do
      assert RemoteAccess.url() == "http://localhost:4002"
      assert RemoteAccess.url("api/mcp") == "http://localhost:4002/api/mcp"
    end
  end

  def mock_system_cmd_complex("tailscale", ["funnel", "status", "--json"], _opts) do
    json = ~s({
      "TCP": {
        "3333": {
          "HTTPS": true
        },
        "3334": {
          "HTTPS": true
        }
      },
      "Web": {
        "my.tailnet:3333": {
          "Handlers": {
            "/": {
              "Proxy": "http://127.0.0.1:4002"
            }
          }
        },
        "my.tailnet:3334": {
          "Handlers": {
            "/": {
              "Proxy": "http://127.0.0.1:4001"
            }
          }
        }
      },
      "AllowFunnel": {
        "my.tailnet:3333": true,
        "my.tailnet:3334": true
      },
      "Foreground": {
        "7edeb8adee154976": {
          "TCP": {
            "3335": {
              "HTTPS": true
            }
          },
          "Web": {
            "my.tailnet:3335": {
              "Handlers": {
                "/": {
                  "Proxy": "http://127.0.0.1:4000"
                }
              }
            }
          },
          "AllowFunnel": {
            "my.tailnet:3335": true
          }
        }
      }
    })
    {json, 0}
  end

  def mock_system_cmd_with_path("tailscale", ["funnel", "status", "--json"], _opts) do
    json = ~s({
      "Foreground": {
        "1b49bd0113eb0615": {
          "TCP": {
            "443": {
              "HTTPS": true
            }
          },
          "Web": {
            "my.tailnet:443": {
              "Handlers": {
                "/meadow": {
                  "Proxy": "http://127.0.0.1:4002"
                }
              }
            }
          },
          "AllowFunnel": {
            "my.tailnet:443": true
          }
        }
      }
    })
    {json, 0}
  end

  def mock_system_cmd_no_funnel("tailscale", ["funnel", "status", "--json"], _opts) do
    {"{}", 0}
  end

  def mock_system_cmd_failure("tailscale", ["funnel", "status", "--json"], _opts) do
    raise ErlangError, original: :enoent, reason: nil
  end
end
