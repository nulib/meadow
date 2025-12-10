import { useMutation } from "@apollo/client";
import { SEND_CHAT_MESSAGE } from "@js/components/Plan/plan.gql";

type SendChatMessageShape = {
  conversationId: string;
  type: string;
  prompt: string;
  query: string;
};

export function useSendChatMessage() {
  const [sendChatMessageMutation, { loading, error, data }] =
    useMutation(SEND_CHAT_MESSAGE);

  const sendChatMessage = ({
    conversationId,
    type,
    prompt,
    query,
  }: SendChatMessageShape) =>
    sendChatMessageMutation({
      variables: {
        conversationId,
        type,
        prompt,
        query,
      },
    });

  return { sendChatMessage, loading, error, data };
}
