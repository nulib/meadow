import { useQuery } from "@apollo/client";
import React, { useEffect } from "react";
import { GET_PLAN, GET_PLAN_CHANGES } from "../plan.gql";
import UILoader from "../../UI/Loader";
import PlanPanelChangesDiff from "./Diff";

const PlanPanelChanges = ({ planChanges, planId }) => {
  const [planLoading, setPlanLoading] = React.useState(false);
  const [proposedChanges, setProposedChanges] = React.useState({});

  const planPending = useQuery(GET_PLAN, {
    variables: { id: planId },
    fetchPolicy: "no-cache",
  });

  console.log({ planPending });
  console.log({ planChanges });

  /**
   * Check if we have any pending changes
   * If so, keep loading until they are resolved
   */
  useEffect(() => {
    const hasPendingChanges = planPending.data?.plan?.status === "PENDING";
    setPlanLoading(hasPendingChanges);
  }, [planPending.data?.plan]);

  /**
   * When planChanges are updated, check if there are proposed changes
   * If so, set them to state and stop loading
   */
  useEffect(() => {
    if (planChanges?.planChange) {
      if (planChanges.planChange.status === "PROPOSED") {
        setPlanLoading(false);
        setProposedChanges(planChanges.planChange);
      }
    }
  }, [planChanges?.planChange]);

  return (
    <div>
      {planLoading ? (
        <UILoader />
      ) : (
        <PlanPanelChangesDiff proposedChanges={proposedChanges} />
      )}
    </div>
  );
};

export default PlanPanelChanges;
