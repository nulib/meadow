defmodule Meadow.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Repo

  using opts do
    shared = Keyword.get(opts, :shared, false)

    quote do
      alias Meadow.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Meadow.DataCase
      import Meadow.TestHelpers

      @moduletag shared: unquote(shared)
    end
  end

  setup tags do
    sandbox =
      case tags do
        %{unboxed: true} -> false
        %{walex: _} -> false
        _ -> true
      end

    shared = tags[:shared] || not tags[:async]
    pid = Sandbox.start_owner!(Repo, sandbox: sandbox, shared: shared)

    on_exit(fn ->
      if not sandbox do
        for table <- ~w(ark_cache works collections file_sets projects ingest_sheets) do
          {:ok, _} = SQL.query(Repo, "TRUNCATE TABLE #{table} CASCADE", [])
        end
      end

      Sandbox.stop_owner(pid)
    end)

    case tags do
      %{walex: modules} ->
        walex_config = Application.get_env(:meadow, WalEx)
        Application.put_env(:meadow, WalEx, Keyword.put(walex_config, :modules, modules))
        on_exit(fn -> Application.put_env(:meadow, WalEx, walex_config) end)

        {WalEx.Supervisor, Application.get_env(:meadow, WalEx)}
        |> start_supervised!()

      _ ->
        :noop
    end

    :ok
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Users.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
