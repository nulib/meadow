defmodule Meadow.Repo do
  use Ecto.Repo,
    otp_app: :meadow,
    adapter: Ecto.Adapters.Postgres

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
end
