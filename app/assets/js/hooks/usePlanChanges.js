import { useSubscription } from "@apollo/client";
import { PLAN_CHANGES } from "@js/components/Plan/plan.gql";

export function usePlanChanges(planId) {
  try {
    const { data, loading, error } = useSubscription(PLAN_CHANGES, {
      variables: { planId },
      shouldResubscribe: true,
      fetchPolicy: "no-cache",
    });

    return { data: data?.planChangesUpdated, loading, error };
  } catch (error) {
    return { data: null, loading: false, error };
  }
}
