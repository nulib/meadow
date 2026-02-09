defmodule MeadowWeb.MCP.SendStatusUpdate do
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
    name: "send_status_update",
    mime_type: "application/json"

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

  def name, do: "send_status_update"

  @impl true
  def execute(%{plan_id: plan_id, message: message}, frame) do
    case plan_id do
      nil ->
        Logger.warning("Status Update: #{message} (no plan ID in metadata)")

      _ ->
        conversation_id = Cachex.get!(Meadow.Cache.Chat.Conversations, plan_id)
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
    error -> MeadowWeb.MCP.Error.error_response(__MODULE__, frame, error)
  end
end
