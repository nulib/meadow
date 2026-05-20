defmodule MeadowWeb.MCP.HordeSupervisor do
  @moduledoc """
  Thin wrapper around Horde.DynamicSupervisor that injects members: :auto.

  Anubis resolves the supervisor module from the :supervisor option but then
  builds the child spec itself as {sup_mod, name: name, strategy: :one_for_one},
  discarding any opts you passed. Providing our own child_spec/1 lets us route
  start_link through this module so we can add members: :auto before forwarding
  to Horde.DynamicSupervisor.
  """

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts) do
    Horde.DynamicSupervisor.start_link(Keyword.merge([members: :auto], opts))
  end

  defdelegate start_child(supervisor, child_spec), to: Horde.DynamicSupervisor
  defdelegate terminate_child(supervisor, pid), to: Horde.DynamicSupervisor
end
