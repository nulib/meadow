defmodule MeadowWeb.MCP.Tools.SendStatusUpdate do
  @moduledoc """
  Sends a status update message for a specific plan

  ## Example Usage

      %{
        plan_id: "plan-uuid",
        message: "Your plan has been updated.",
        agent: "agent"
      }
  """

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "application/json"

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Notification
  require Logger

  schema do
    field(:plan_id, :string,
      description: "The unique identifier for the plan",
      required: true
    )

    field(:message, :string,
      description: "The status update message content to send",
      required: true
    )

    field(:agent, :string,
      description: "Identify yourself as an agent or a sub-agent",
      required: true
    )
  end

  @impl true
  def execute(%{plan_id: plan_id, message: message}, frame) do
    case plan_id do
      nil ->
        Logger.warning("Status Update: #{message} (no plan ID in metadata)")

      _ ->
        conversation_id = Cachex.get!(Meadow.Cache.Chat.Conversations, plan_id)
        Logger.info("Status Update for Plan #{plan_id} (conversation #{conversation_id}): #{message}")
        %{
          conversation_id: conversation_id,
          type: "status_update",
          message: message,
          plan_id: plan_id
        }
        |> Notification.publish(chat_response: "conversation:#{conversation_id}")
    end
    {:reply, Response.tool() |> Response.text("ok"), frame}
  rescue
    error -> {:error, MCPError.execution(error), frame}
  end
end
