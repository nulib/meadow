defmodule MeadowWeb.MCP.GlobalRegistry do
  @moduledoc """
  Global registry adapter for Anubis that works across clustered nodes.
  Uses :global instead of Registry for cross-node process discovery.
  """

  @behaviour Anubis.Server.Registry.Adapter

  require Logger

  def child_spec(opts) do
    # :global is built-in, no child process needed
    %{
      id: __MODULE__,
      start:
        {Horde.Registry, :start_link,
         [
           [
             name: __MODULE__,
             keys: :unique,
             members: :auto
           ] ++ opts
         ]},
      type: :supervisor
    }
  end

  def server(module) do
    {:via, Horde.Registry, {__MODULE__, {:server, module}}}
  end

  def task_supervisor(module) when is_atom(module) do
    {:via, Horde.Registry, {__MODULE__, {:task_supervisor, module}}}
  end

  def server_session(server, session_id) do
    {:via, Horde.Registry, {__MODULE__, {:session, server, session_id}}}
  end

  def transport(module, type) when is_atom(module) do
    {:via, Horde.Registry, {__MODULE__, {:transport, module, type}}}
  end

  def supervisor(kind \\ :supervisor, module) do
    {:via, Horde.Registry, {__MODULE__, {kind, module}}}
  end

  def whereis_server_session(module, session_id) do
    Horde.Registry.whereis_name({__MODULE__, {:session, module, session_id}})
  end

  def whereis_supervisor(server, kind \\ :supervisor) when is_atom(server) do
    Horde.Registry.whereis_name({__MODULE__, {kind, server}})
  end

  def whereis_server(module) when is_atom(module) do
    Horde.Registry.whereis_name({__MODULE__, {:server, module}})
  end

  def whereis_transport(module, type) when is_atom(module) and is_atom(type) do
    Horde.Registry.whereis_name({__MODULE__, {:transport, module, type}})
  end
end
