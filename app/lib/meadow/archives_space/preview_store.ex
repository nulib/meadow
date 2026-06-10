defmodule Meadow.ArchivesSpace.PreviewStore do
  @moduledoc """
  Short-lived in-memory store for ArchivesSpace AI import previews.

  The ingest-sheet AI preview flow has a persisted sheet to write previews
  to, but the ArchivesSpace import preview is generated on demand for a
  modal and never creates a sheet. The metadata agent still runs
  out-of-process (in a lambda) and submits its structured previews back
  through the `submit_archives_space_previews` MCP tool — a different BEAM
  process than the resolver that launched it. This Agent is the
  cross-process channel: the resolver opens a one-off token, the MCP tool
  writes previews to it, and the resolver reads them back and discards the
  token.
  """

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc "Registers a token with an empty preview list so a read before the agent submits returns `[]` rather than `nil`."
  def open(token), do: Agent.update(__MODULE__, &Map.put(&1, token, []))

  @doc "Stores the previews submitted for a token."
  def put(token, previews), do: Agent.update(__MODULE__, &Map.put(&1, token, previews))

  @doc "Returns the previews stored for a token, or `nil` if the token is unknown."
  def get(token), do: Agent.get(__MODULE__, &Map.get(&1, token))

  @doc "Forgets a token and its previews."
  def close(token), do: Agent.update(__MODULE__, &Map.delete(&1, token))
end
