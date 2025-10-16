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
        # Publish plan_id immediately to frontend
        Absinthe.Subscription.publish(
          MeadowWeb.Endpoint,
          %{
            conversation_id: conversation_id,
            message: "Plan created with ID: #{plan.id}",
            type: type,
            plan_id: plan.id
          },
          chat_response: "conversation:#{conversation_id}"
        )

        # Run agent in background
        Task.start(fn ->
          {:ok, ai_response} = MeadowAI.query(prompt, context: %{query: query, plan_id: plan.id})

          # Publish final agent response
          Absinthe.Subscription.publish(
            MeadowWeb.Endpoint,
            %{
              conversation_id: conversation_id,
              message: ai_response,
              type: type,
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
