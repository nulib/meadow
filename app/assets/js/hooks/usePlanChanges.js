import { useQuery, useSubscription } from "@apollo/client/react";
import {
  GET_PLAN_CHANGES,
  PLAN_CHANGES_UPDATED,
} from "@js/components/Plan/plan.gql";

const hasObjectChanges = (value) =>
  Boolean(value && typeof value === "object" && Object.keys(value).length > 0);

const hasPlanChangePayload = (planChange) =>
  Boolean(
    planChange &&
    (hasObjectChanges(planChange.add) ||
      hasObjectChanges(planChange.delete) ||
      hasObjectChanges(planChange.replace)),
  );

export function usePlanChanges(planId) {
  try {
    const skip = !planId;

    const {
      data: subscriptionData,
      loading: subscriptionLoading,
      error: subscriptionError,
    } = useSubscription(PLAN_CHANGES_UPDATED, {
      variables: { planId },
      skip,
      shouldResubscribe: true,
      fetchPolicy: "no-cache",
    });

    const {
      data: queryData,
      loading: queryLoading,
      error: queryError,
    } = useQuery(GET_PLAN_CHANGES, {
      variables: { planId },
      skip,
      fetchPolicy: "no-cache",
      pollInterval: 2000,
    });

    const fallbackPlanChange =
      queryData?.planChanges?.find(hasPlanChangePayload) ||
      queryData?.planChanges?.[0] ||
      null;

    const data =
      subscriptionData?.planChangesUpdated ||
      (fallbackPlanChange
        ? { planId, action: "queried", planChange: fallbackPlanChange }
        : null);

    const loading = !skip && !data && (subscriptionLoading || queryLoading);
    const error = subscriptionError || queryError;

    return { data, loading, error };
  } catch (error) {
    return { data: null, loading: false, error };
  }
}
