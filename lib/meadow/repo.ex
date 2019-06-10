defmodule Meadow.Repo do
  use Ecto.Repo,
    otp_app: :meadow,
    adapter: Ecto.Adapters.Postgres
end
