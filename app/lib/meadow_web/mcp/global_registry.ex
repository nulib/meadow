defmodule MeadowWeb.MCP.GlobalRegistry do
  @moduledoc """
  Distributed session registry using `:pg` (OTP process groups).
  Taken from https://gist.github.com/sb8244/47e6eb1f03d8f1a4c5c7403a00668ded

  Replaces `Anubis.Server.Registry.Local` for multi-node deployments.
  Each session is registered as a member of its own `:pg` group, keyed
  by session ID within a per-server-module scope. `:pg` handles automatic
  cleanup when session processes terminate and propagates membership across
  all connected nodes in the BEAM cluster.

  ## How it works

  - Each server module gets its own `:pg` scope atom (derived from registry name)
  - Each session occupies its own group within that scope (group = session_id binary)
  - PIDs are registered from whatever node starts the session
  - Lookups from any node return the PID regardless of which node owns it
  - Cross-node `GenServer.call/3` is transparent in BEAM

  ## Single-node fallback

  On a single node `:pg` behaves identically to a local registry with slightly
  more overhead. This makes it safe to use in development.

  ## Testing on Anubis Upgrade

  This module uses private internal details to get a working MCP with misbehaving
  clients. So, if there's an upgrade it could end up not working.

  Test it by using the `npx asoorm/inspector#fix/oauth-cors-proxy-support` command, connecting,
  listing tools, restarting the server, and listing tools again.
  """

  require Logger

  alias Anubis.Server.Registry
  alias Anubis.Server.Supervisor, as: ServerSupervisor

  @behaviour Registry

  @impl Registry
  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    scope = pg_scope(name)

    %{
      id: {__MODULE__, name},
      start: {:pg, :start_link, [scope]},
      type: :worker,
      restart: :permanent
    }
  end

  @impl Registry
  def register_session(name, session_id, pid) do
    scope = pg_scope(name)
    group = session_id

    :pg.join(scope, group, pid)
    :ok
  end

  @impl Registry
  def lookup_session(name, session_id) do
    case :pg.get_members(pg_scope(name), session_id) do
      [pid | _] ->
        {:ok, pid}

      [] ->
        Logger.info("[#{__MODULE__}] session #{session_id} not found, resurrecting")
        resurrect_session(name, session_id)
    end
  end

  @doc """
  In the normal path we rely on :pg automatic cleanup (process exit removes
  membership). This explicit leave is provided for callers that need
  immediate removal, e.g. DELETE /mcp.
  """
  @impl Registry
  def unregister_session(name, session_id) do
    scope = pg_scope(name)
    group = session_id

    members = :pg.get_members(scope, group)

    Enum.each(members, fn pid ->
      :pg.leave(scope, group, pid)
    end)

    :ok
  end

  # sobelow_skip ["DOS.BinToAtom"] The incoming atom is from the system
  defp pg_scope(registry_name), do: :"#{registry_name}.pg"

  defp resurrect_session(name, session_id) do
    server = MeadowWeb.MCP.Server
    session_config = ServerSupervisor.get_session_config(server)

    opts = [
      session_id: session_id,
      server_module: server,
      name: Registry.session_name(server, session_id),
      transport: session_config.transport,
      registry: __MODULE__,
      session_idle_timeout: session_config.session_idle_timeout || :timer.minutes(30),
      timeout: session_config.timeout,
      task_supervisor: session_config.task_supervisor
    ]

    case ServerSupervisor.start_session(server, opts) do
      {:ok, pid} ->
        # Pre-initialize so tool calls work without a re-handshake.
        # Use :sys.replace_state directly because there's no way to set this directly, as it's not intended
        :sys.replace_state(pid, fn state ->
          %{
            state
            | initialized: true,
              protocol_version: "2024-11-05",
              protocol_module: Anubis.Protocol.V2024_11_05
          }
        end)

        # We must immediately register because we need the session to be registered outside of the normal flow
        register_session(name, session_id, pid)
        Logger.info("[#{__MODULE__}] resurrected session #{session_id}")

        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:error, reason} ->
        Logger.error(
          "[#{__MODULE__}] failed to resurrect session #{session_id}: #{inspect(reason)}"
        )

        {:error, :not_found}
    end
  end
end
