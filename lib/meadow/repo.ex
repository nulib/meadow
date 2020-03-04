defmodule Meadow.Repo do
  use Ecto.Repo,
    otp_app: :meadow,
    adapter: Ecto.Adapters.Postgres

  def init(_, opts), do: {:ok, opts}

  def listen(event_name) do
    with {:ok, pid} <- Postgrex.Notifications.start_link(__MODULE__.config()),
         {:ok, ref} <- Postgrex.Notifications.listen(pid, event_name) do
      {:ok, pid, ref}
    end
  end
end
