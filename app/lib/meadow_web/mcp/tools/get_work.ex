defmodule MeadowWeb.MCP.Tools.GetWork do
  @moduledoc """
  Return a work resource
  """

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
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
    case Works.get_work(work_id)
         |> Repo.preload([
           :collection,
           file_sets: Meadow.Data.Schemas.FileSet.metadata_preloads()
         ]) do
      nil -> {:error, MCPError.resource(:not_found, %{work_id: work_id}), frame}
      work -> {:reply, Response.tool() |> Response.structured(work), frame}
    end
  end
end
