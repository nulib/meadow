defmodule MeadowWeb.Resolvers.Chat do
  @moduledoc """
  Absinthe GraphQL query resolver for Chat Context

  """
  alias Meadow.Data.Planner
  require Logger

  def send_chat_message(
        _,
        %{conversation_id: conversation_id, type: type, query: query, prompt: prompt},
        _
      ) do
    case Planner.create_plan(%{prompt: prompt, query: query}) do
      {:ok, plan} ->
        # Publish plan_id immediately to frontend with dedicated message type
        Cachex.put!(Meadow.Cache.Chat.Conversations, plan.id, conversation_id)

        {:ok, heartbeat_pid} =
          Meadow.Notification.Heartbeat.start(
            %{
              conversation_id: conversation_id,
              message: "",
              type: "heartbeat",
              plan_id: plan.id
            },
            chat_response: "conversation:#{conversation_id}"
          )

        Meadow.Notification.publish(
          %{
            conversation_id: conversation_id,
            message: "Plan created with ID: #{plan.id}",
            type: "plan_id",
            plan_id: plan.id
          },
          chat_response: "conversation:#{conversation_id}"
        )

        # Run agent in background
        Task.start(fn ->
          try do
            case MeadowAI.query(prompt, context: %{query: query, plan_id: plan.id}) do
              {:ok, ai_response} ->
                # Publish final agent response as chat message
                Meadow.Notification.publish(
                  %{
                    conversation_id: conversation_id,
                    message: ai_response,
                    type: "chat",
                    plan_id: plan.id
                  },
                  chat_response: "conversation:#{conversation_id}"
                )

              {:error, reason} ->
                Logger.error("AI query error: #{inspect(reason)}")
                Planner.mark_plan_error(plan, inspect(reason))
            end
          after
            Meadow.Notification.Heartbeat.stop(heartbeat_pid)
          end
        end)

        {:ok, %{conversation_id: conversation_id, type: type, query: query, prompt: prompt}}

      {:error, changeset} ->
        {:error, message: "Failed to create plan", details: changeset}
    end
  end
end
