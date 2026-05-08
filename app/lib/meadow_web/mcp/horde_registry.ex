defmodule MeadowWeb.MCP.HordeRegistry do
  @moduledoc """
  Anubis.Server.Registry adapter backed by Horde.Registry.

  Returning a {:via, Horde.Registry, ...} name from session_name/2 causes the
  session process to register itself in the distributed registry at start_link
  time, so register_session/3 and unregister_session/2 are no-ops. Horde
  automatically removes entries when a process exits.
  """

  @behaviour Anubis.Server.Registry

  @impl Anubis.Server.Registry
  def child_spec(opts) do
    name = Keyword.fetch!(opts, :name)

    %{
      id: {Horde.Registry, name},
      start: {Horde.Registry, :start_link, [[keys: :unique, name: name, members: :auto]]},
      type: :supervisor
    }
  end

  @impl Anubis.Server.Registry
  def session_name(registry_name, session_id),
    do: {:via, Horde.Registry, {registry_name, session_id}}

  @impl Anubis.Server.Registry
  def register_session(_name, _session_id, _pid), do: :ok

  @impl Anubis.Server.Registry
  def lookup_session(name, session_id) do
    case Horde.Registry.lookup(name, session_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  @impl Anubis.Server.Registry
  def unregister_session(_name, _session_id), do: :ok
end
