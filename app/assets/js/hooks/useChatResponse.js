import { useSubscription } from "@apollo/client";
import { CHAT_RESPONSE } from "@js/components/Plan/plan.gql";

export function useChatResponse(conversationId) {
  try {
    const { data, loading, error } = useSubscription(CHAT_RESPONSE, {
      variables: { conversationId },
      shouldResubscribe: true,
      fetchPolicy: "no-cache",
    });

    return { data: data?.chatResponse, loading, error };
  } catch (error) {
    return { data: null, loading: false, error };
  }
}
