defmodule Mix.Tasks.Meadow.Grafana do
  @moduledoc """
  Base module for Grafana tasks
  """

  defmodule Setup do
    @moduledoc """
    Generate a Grafana API key and set it as an environment variable used in PromEx configuration.
    """
    use Mix.Task

    @shortdoc @moduledoc
    def run(_) do
      Application.ensure_all_started(:hackney)

      unless grafana_running?() do
        Mix.raise("Error: Grafana is not running.")
      end

      with {:ok, message} <- create_data_source() do
        IO.puts(message)
      else
        {:error, status} -> IO.puts(status)
      end

      with {:ok, key} <- create_api_key() do
        path = Path.join([File.cwd!() | ~w(config grafana.env)])
        File.write!(path, "GRAFANA_API_KEY=#{key}")
        IO.puts("grafana.env with API Key #{key} written to #{path}")
      else
        {:error, status} ->
          Mix.raise("Error: could not generate API key, received #{status} response")
      end
    end

    defp grafana_running? do
      case HTTPoison.head("http://localhost:3009/api/health") do
        {:ok, %{status_code: status}} when status in 200..299 -> true
        _ -> false
      end
    end

    defp create_data_source do
      body =
        Jason.encode!(%{
          name: "Prometheus",
          type: "prometheus",
          url: "http://prometheus:9090",
          access: "proxy",
          basicAuth: false
        })

      headers = [{"Content-type", "application/json"}]

      case HTTPoison.post("http://admin:admin@localhost:3009/api/datasources", body, headers) do
        {:ok, %{status_code: status}} when status in 200..299 ->
          {:ok, "Prometheus data source created"}

        {:ok, %{status_code: status}} when status == 409 ->
          {:ok, "Prometheus data source already exists :)"}

        {_, %{status_code: status}} ->
          {:error, status}
      end
    end

    defp create_api_key do
      body =
        Jason.encode!(%{
          name: "meadow",
          role: "Editor",
          secondsToLive: 31_536_000
        })

      headers = [{"Content-type", "application/json"}]

      case HTTPoison.post("http://admin:admin@localhost:3009/api/auth/keys", body, headers) do
        {:ok, %{status_code: status, body: body}} when status in 200..299 ->
          key = Jason.decode!(body) |> Map.get("key")
          {:ok, key}

        {:ok, %{status_code: status}} when status == 409 ->
          delete_api_key()
          create_api_key()

        {_, %{status_code: status}} ->
          {:error, status}
      end
    end

    defp delete_api_key do
      with {:ok, id} <- meadow_api_key_id() do
        headers = [{"Content-type", "application/json"}]

        case HTTPoison.delete("http://admin:admin@localhost:3009/api/auth/keys/#{id}", headers) do
          {:ok, %{status_code: status, body: body}} when status in 200..299 ->
            IO.puts("Deleted existing Grafana API Key")

            response =
              body
              |> Jason.decode!()

            {:ok, response}

          {_, %{status_code: status}} ->
            {:error, status}
        end
      end
    end

    defp meadow_api_key_id do
      userpass = "admin:admin"

      headers = [
        {"Authorization", "Basic #{:base64.encode(userpass)}"},
        {"Content-type", "application/json"}
      ]

      case HTTPoison.get("http://localhost:3009/api/auth/keys", headers) do
        {:ok, %{status_code: status, body: body}} when status in 200..299 ->
          meadow_api_key_id =
            body
            |> Jason.decode!()
            |> Enum.find(fn key -> Map.get(key, "name") == "meadow" end)
            |> Map.get("id")

          {:ok, meadow_api_key_id}

        {_, %{status_code: status}} ->
          {:error, status}
      end
    end
  end
end
