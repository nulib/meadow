defmodule Meadow.Repo do
  use Ecto.Repo,
    otp_app: :meadow,
    adapter: Ecto.Adapters.Postgres

  alias Meadow.Utils.Logging

  require Logger
  require Logging
  require WaitForIt

  def init(_, opts), do: {:ok, opts}

  def listen(event_name) do
    notification_listener_pid()
    |> Postgrex.Notifications.listen(event_name)
  end

  defp notification_listener_pid do
    case Process.whereis(Meadow.Postgrex.Notifications) do
      nil -> start_notification_listener()
      pid -> pid
    end
  end

  defp start_notification_listener do
    with {:ok, pid} <-
           __MODULE__.config()
           |> Keyword.put_new(:name, Meadow.Postgrex.Notifications)
           |> Postgrex.Notifications.start_link() do
      pid
    end
  end

  def wait_for_connection do
    Logger.info("Waiting for active database connection...")
    canary() |> WaitForIt.wait(timeout: 60_000, frequency: 1_000)
  end

  defp canary do
    Logging.with_log_level :info do
      case __MODULE__.query("SELECT 1") do
        {:ok, %{rows: [[1]]}} -> :ok
        _ -> :error
      end
    end
  rescue
    _ in DBConnection.ConnectionError -> :error
  end
end
