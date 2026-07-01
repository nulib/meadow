defmodule MeadowWeb.MCP.Tools.GetWork do
  @moduledoc """
  Return a work resource
  """

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Data.Schemas.WorkDescriptiveMetadata
  alias Meadow.Data.Works
  alias Meadow.Repo

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "application/json"

  schema do
    field :work_id, :string
  end

  @impl true
  def execute(%{work_id: work_id}, frame) do
    case Works.get_work(work_id) |> Repo.preload([:file_sets, :collection]) do
      nil -> {:error, MCPError.resource(:not_found, %{work_id: work_id}), frame}
      work -> {:reply, Response.tool() |> Response.structured(agent_view(work)), frame}
    end
  end

  # Present repeating free-text fields to the agent as bare strings rather than
  # `{id, value}` objects, so it treats them as free text (replace) instead of
  # controlled terms (add/delete with `{term: {id}}`).
  defp agent_view(%{descriptive_metadata: %WorkDescriptiveMetadata{} = dm} = work),
    do: %{work | descriptive_metadata: WorkDescriptiveMetadata.flatten_value_entries(dm)}

  defp agent_view(work), do: work
end
