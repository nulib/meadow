import { useMutation } from "@apollo/client";
import React, { useEffect } from "react";
import {
  APPLY_PLAN,
  UPDATE_PLAN_STATUS,
  UPDATE_PROPOSED_PLAN_CHANGE_STATUSES,
} from "@js/components/Plan/plan.gql";
import UILoader from "@js/components/UI/Loader";
import PlanPanelChangesDiff from "@js/components/Plan/Panel/Diff";
import { IconCheckAlt, IconMagic } from "@js/components/Icon";

const PlanPanelChanges = ({ changes, id, loadingMessage, plan, target }) => {
  const [loading, setLoading] = React.useState(true);
  const [isApproved, setIsApproved] = React.useState(false);
  const [isApplying, setIsApplying] = React.useState(false);
  const [applyStartedAt, setApplyStartedAt] = React.useState(null);
  const [showCompleted, setShowCompleted] = React.useState(false);

  const status = plan?.status || "PENDING";

  const [applyPlan] = useMutation(APPLY_PLAN);
  const [updatePlanStatus] = useMutation(UPDATE_PLAN_STATUS);
  const [updateProposedPlanChangeStatuses] = useMutation(
    UPDATE_PROPOSED_PLAN_CHANGE_STATUSES,
  );

  useEffect(() => {
    switch (status) {
      case "PENDING":
        setLoading(true);
        // reset UI-phase flags when backing out
        setIsApplying(false);
        setApplyStartedAt(null);
        setShowCompleted(false);
        break;
      case "PROPOSED":
        // set timeout to simulate loading
        setTimeout(() => {
          setLoading(false);
          setIsApproved(false);
          setIsApplying(false);
          setApplyStartedAt(null);
          setShowCompleted(false);
        }, 2000);
        break;
      case "APPROVED":
        setLoading(false);
        setShowCompleted(false);
        break;
      case "COMPLETED":
        // handled below to enforce min spinner time
        break;
    }
  }, [status]);

  /**
   * Handle the COMPLETED state with an enforced minimum
   * of 1s spinner time to limit blinking between states.
   */
  useEffect(() => {
    if (status !== "COMPLETED") return;
    if (isApplying && applyStartedAt) {
      const elapsed = Date.now() - applyStartedAt;
      const remaining = Math.max(1000 - elapsed, 0);
      const t = setTimeout(() => {
        setIsApplying(false);
        setShowCompleted(true);
      }, remaining);
      return () => clearTimeout(t);
    }

    /**
     * If we reach COMPLETED state but we're not in the applying
     * phase, we need to show the completed state immediately.
     */
    setShowCompleted(true);
  }, [status, isApplying, applyStartedAt]);

  const handleApproveChanges = async () => {
    try {
      await updateProposedPlanChangeStatuses({
        variables: { planId: id, status: "APPROVED" },
        onCompleted: ({ updateProposedPlanChangeStatuses }) => {
          if (updateProposedPlanChangeStatuses) {
            updatePlanStatus({
              variables: { id, status: "APPROVED" },
              onCompleted: () => setIsApproved(true),
            });
          }
        },
      });
    } catch (e) {
      console.error("Error approving changes:", e);
    }
  };

  const handleApplyChanges = () => {
    try {
      setIsApplying(true);
      setApplyStartedAt(Date.now());
      setShowCompleted(false);

      applyPlan({
        variables: { id },
        onCompleted: () => {},
      });
    } catch (e) {
      setIsApplying(false);
      setApplyStartedAt(null);
    }
  };

  return (
    <div className="plan-panel-changes">
      {loading ? (
        <div className="plan-panel-changes--loading plan-placeholder">
          {target.thumbnails}
          <UILoader />
          {loadingMessage && (
            <span className="plan-panel-changes--loading--message">
              {loadingMessage}
            </span>
          )}
        </div>
      ) : (
        <div className="plan-panel-changes--content">
          <div className="plan-panel-changes--status">
            <span data-status={status} data-active={status === "PROPOSED"}>
              Proposed
            </span>
            <hr className="plan-panel-changes--status--divider" />
            <span data-status={status} data-active={status === "APPROVED"}>
              Approved
            </span>
            <hr className="plan-panel-changes--status--divider" />
            <span
              data-status={status}
              data-active={showCompleted || status === "COMPLETED"}
            >
              Applied
            </span>
          </div>

          <div className="plan-panel-changes--actions">
            <h3 className="mb-5">Changes</h3>
            <div>
              {/* Approve Changes button only shown when proposed */}
              {status === "PROPOSED" && (
                <button onClick={handleApproveChanges} data-variant="approve">
                  Approve Changes
                </button>
              )}

              {/* Apply Changes button only shown when approved */}
              {status === "APPROVED" && !isApplying && (
                <button
                  onClick={handleApplyChanges}
                  data-variant="primary"
                  disabled={!isApproved || isApplying}
                >
                  {isApplying ? "Applying…" : "Apply Changes"}
                </button>
              )}

              {/* Spinner during wait window, minimum 1 second */}
              {(isApplying || (status === "COMPLETED" && !showCompleted)) && (
                <span>
                  <IconMagic />
                  Applying changes…
                </span>
              )}

              {/* Success message after applying changes */}
              {showCompleted && (
                <span>
                  <IconCheckAlt /> Your changes have been applied.
                </span>
              )}
            </div>
          </div>

          <PlanPanelChangesDiff proposedChanges={changes?.planChange || {}} />
        </div>
      )}
    </div>
  );
};

export default PlanPanelChanges;
