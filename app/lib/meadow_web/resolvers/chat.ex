defmodule MeadowWeb.Resolvers.Chat do
  @moduledoc """
  Absinthe GraphQL query resolver for Chat Context

  """
  alias Meadow.Data.Planner

  def send_chat_message(
        _,
        %{conversation_id: conversation_id, type: type, query: query, prompt: prompt},
        _
      ) do
    case Planner.create_plan(%{prompt: prompt, query: query}) do
      {:ok, plan} ->
        # Publish plan_id immediately to frontend with dedicated message type
        Cachex.put!(Meadow.Cache.Chat.Conversations, plan.id, conversation_id)
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
          {:ok, ai_response} = MeadowAI.query(prompt, context: %{query: query, plan_id: plan.id})

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
        end)

        {:ok, %{conversation_id: conversation_id, type: type, query: query, prompt: prompt}}

      {:error, changeset} ->
        {:error, message: "Failed to create plan", details: changeset}
    end
  end
end
