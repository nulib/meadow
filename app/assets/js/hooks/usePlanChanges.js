import { useSubscription } from "@apollo/client";
import { PLAN_CHANGES_UPDATED } from "@js/components/Plan/plan.gql";

export function usePlanChanges(planId) {
  try {
    const { data, loading, error } = useSubscription(PLAN_CHANGES_UPDATED, {
      variables: { planId },
      shouldResubscribe: true,
      fetchPolicy: "no-cache",
    });

    return { data: data?.planChangesUpdated, loading, error };
  } catch (error) {
    return { data: null, loading: false, error };
  }
}
