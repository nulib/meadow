import { useQuery } from "@apollo/client";
import React, { useEffect } from "react";
import { GET_PLAN } from "@js/components/Plan/plan.gql";
import UILoader from "@js/components/UI/Loader";
import PlanPanelChangesDiff from "@js/components/Plan/Panel/Diff";
import { Button } from "@nulib/design-system";
import { set } from "react-hook-form";
import { IconCheck, IconCheckAlt } from "../../Icon";

const PlanPanelChanges = ({ changes, id, target }) => {
  const [loading, setLoading] = React.useState(true);
  const [proposedChanges, setProposedChanges] = React.useState(null);
  const [isApproved, setIsApproved] = React.useState(false);

  const pending = useQuery(GET_PLAN, {
    variables: { id },
    fetchPolicy: "no-cache",
  });

  /**
   * Check if we have any pending changes
   * If so, keep loading until they are resolved
   */
  useEffect(() => {
    if (!pending.data?.plan) return;

    const hasPendingChanges = pending.data?.plan?.status === "PENDING";
    setLoading(hasPendingChanges);
  }, [pending.data?.plan]);

  /**
   * When changes are updated, check if there are proposed changes
   * If so, set them to state and stop loading
   */
  useEffect(() => {
    if (changes?.planChange) {
      if (changes.planChange.status === "PROPOSED") {
        setLoading(false);
        setProposedChanges(changes.planChange);
      }
    }
  }, [changes?.planChange]);

  /**
   * Handle Approve Changes button click
   */
  const handleApproveChanges = () => {
    setIsApproved(!isApproved);
    console.log("Approve Changes clicked");
  };

  /**
   * Handle Apply Changes button click
   */
  const handleApplyChanges = () => {
    console.log("Apply Changes clicked");
  };

  return (
    <div className="plan-panel-changes">
      {loading ? (
        <div className="plan-panel-changes--loading plan-placeholder">
          {target.thumbnails}
          <p className="is-6">{target.title}</p>
          <UILoader />
        </div>
      ) : (
        <div className="plan-panel-changes--content">
          <div className="plan-panel-changes--actions">
            <h3 className="mb-5">Proposed Changes</h3>
            <div>
              <button
                onClick={handleApproveChanges}
                data-variant="approve"
                data-approved={isApproved}
              >
                <span>
                  <IconCheckAlt />
                </span>
                Approve
              </button>
              <button
                onClick={handleApplyChanges}
                data-variant="primary"
                disabled={!isApproved}
              >
                Apply
              </button>
            </div>
          </div>
          <PlanPanelChangesDiff proposedChanges={proposedChanges || {}} />
        </div>
      )}
    </div>
  );
};

export default PlanPanelChanges;
