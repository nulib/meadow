defmodule Meadow.Repo.Indexing do
  @moduledoc """
  Dedicated Repo for indexing operations
  """

  use Ecto.Repo,
    otp_app: :meadow,
    adapter: Ecto.Adapters.Postgres

  def init(_, opts), do: {:ok, opts}
end
