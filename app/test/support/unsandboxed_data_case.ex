defmodule Meadow.UnsandboxedDataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  direct, unsandboxed access to the application's data
  layer (e.g., for testing database triggers).

  Use this module with caution:
  * Use it only with `async: false`
  * Clean up any data changes manually
  """

  use ExUnit.CaseTemplate

  defmodule Repo do
    @moduledoc false
    use Ecto.Repo, adapter: Ecto.Adapters.Postgres, otp_app: :meadow

    def listen(event_name), do: Meadow.Repo.listen(event_name)
  end

  setup_all do
    Application.put_env(
      :meadow,
      Meadow.UnsandboxedDataCase.Repo,
      Application.get_env(:meadow, Meadow.Repo)
      |> Keyword.delete(:pool)
      |> Keyword.put(:show_sensitive_data_on_connection_error, true)
    )

    start_supervised!(Meadow.UnsandboxedDataCase.Repo)
    :ok
  end

  setup do
    {:ok, %{repo: Meadow.UnsandboxedDataCase.Repo}}
  end
end
