import { useQuery, useSubscription } from "@apollo/client/react";
import { GET_PLAN, PLAN_UPDATED } from "@js/components/Plan/plan.gql";

export function usePlan(planId) {
  try {
    const skip = !planId;

    const {
      data: subscriptionData,
      loading: subscriptionLoading,
      error: subscriptionError,
    } = useSubscription(PLAN_UPDATED, {
      variables: { planId },
      skip,
      shouldResubscribe: true,
      fetchPolicy: "no-cache",
    });

    const {
      data: queryData,
      loading: queryLoading,
      error: queryError,
    } = useQuery(GET_PLAN, {
      variables: { id: planId },
      skip,
      fetchPolicy: "no-cache",
      pollInterval: 2000,
    });

    const data = subscriptionData?.planUpdated || queryData?.plan || null;
    const loading = !skip && !data && (subscriptionLoading || queryLoading);
    const error = subscriptionError || queryError;

    return { data, loading, error };
  } catch (error) {
    return { data: null, loading: false, error };
  }
}
