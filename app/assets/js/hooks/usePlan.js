import { useSubscription } from "@apollo/client";
import { PLAN_UPDATED } from "@js/components/Plan/plan.gql";

export function usePlan(planId) {
  try {
    const { data, loading, error } = useSubscription(PLAN_UPDATED, {
      variables: { planId },
      shouldResubscribe: true,
      fetchPolicy: "no-cache",
    });

    return { data: data?.planUpdated, loading, error };
  } catch (error) {
    return { data: null, loading: false, error };
  }
}
