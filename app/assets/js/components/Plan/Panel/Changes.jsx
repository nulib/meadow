import { useMutation } from "@apollo/client";
import React, { useEffect } from "react";
import {
  APPLY_PLAN,
  UPDATE_PLAN_STATUS,
  UPDATE_PROPOSED_PLAN_CHANGE_STATUSES,
} from "@js/components/Plan/plan.gql";
import UILoader from "@js/components/UI/Loader";
import UISkeleton from "@js/components/UI/Skeleton";
import PlanPanelChangesDiff from "@js/components/Plan/Panel/Diff";
import { IconMagic } from "@js/components/Icon";

const PlanPanelChanges = ({
  changes,
  id,
  loadingMessage,
  plan,
  summary,
  originalPrompt,
  target,
  onCompleted,
}) => {
  const [loading, setLoading] = React.useState(true);
  const [isApproved, setIsApproved] = React.useState(false);
  const [isApplying, setIsApplying] = React.useState(false);
  const [applyStartedAt, setApplyStartedAt] = React.useState(null);

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
        break;
      case "PROPOSED":
        // set timeout to simulate loading
        setTimeout(() => {
          setLoading(false);
          setIsApproved(false);
          setIsApplying(false);
          setApplyStartedAt(null);
        }, 2000);
        break;
      case "APPROVED":
        setLoading(false);
        break;
      case "REJECTED":
      case "ERROR":
      case "COMPLETED":
        // handled in separate useEffect
        break;
    }
  }, [status]);

  /**
   * Handle terminal states (REJECTED, ERROR, COMPLETED)
   * Reset to initial screen and show toast notification
   */
  useEffect(() => {
    if (status === "REJECTED") {
      onCompleted?.(originalPrompt, "REJECTED");
      return;
    }

    if (status === "ERROR") {
      onCompleted?.(originalPrompt, "ERROR");
      return;
    }

    if (status === "COMPLETED") {
      // Enforce minimum spinner time of 1s
      if (isApplying && applyStartedAt) {
        const elapsed = Date.now() - applyStartedAt;
        const remaining = Math.max(1000 - elapsed, 0);
        const t = setTimeout(() => {
          setIsApplying(false);
          setTimeout(() => {
            onCompleted?.(null, "COMPLETED");
          }, 500);
        }, remaining);
        return () => clearTimeout(t);
      }
      // If not applying, reset immediately
      setTimeout(() => {
        onCompleted?.(null, "COMPLETED");
      }, 500);
    }
  }, [status, isApplying, applyStartedAt, onCompleted, originalPrompt]);

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

  const handleRejectChanges = () => {
    try {
      updatePlanStatus({
        variables: { id, status: "REJECTED" },
        onCompleted: () => {},
      });
    } catch (e) {
      console.error("Error rejecting changes:", e);
    }
  };

  const handleApplyChanges = () => {
    try {
      setIsApplying(true);
      setApplyStartedAt(Date.now());

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
              data-active={status === "COMPLETED"}
            >
              Applied
            </span>
          </div>

          <div className="plan-panel-changes--actions">
            <h3 className="mb-5">Changes</h3>
            <div>
              {/* Approve Changes button only shown when proposed */}
              {status === "PROPOSED" && (
                <>
                  <button onClick={handleRejectChanges} data-variant="reject">
                    Reject Changes
                  </button>
                  <button onClick={handleApproveChanges} data-variant="approve">
                    Approve Changes
                  </button>
                </>
              )}

              {/* Apply Changes button only shown when approved */}
              {status === "APPROVED" && !isApplying && (
                <>
                  <button onClick={handleRejectChanges} data-variant="reject">
                    Reject Changes
                  </button>
                  <button
                    onClick={handleApplyChanges}
                    data-variant="primary"
                    disabled={!isApproved || isApplying}
                  >
                    {isApplying ? "Applying…" : "Apply Changes"}
                  </button>
                </>
              )}

              {/* Spinner during apply */}
              {isApplying && (
                <span>
                  <IconMagic />
                  Applying changes…
                </span>
              )}
            </div>
          </div>

          <div className="plan-panel-changes--prompt mt-5 mb-5">
            <h3 className="mb-3">Prompt</h3>
            {originalPrompt ? (
              <p style={{ whiteSpace: "pre-line" }}>{originalPrompt}</p>
            ) : (
              <UISkeleton type="text" rows={2} />
            )}
          </div>

          {summary ? (
            <div className="plan-panel-changes--summary mt-5 mb-5">
              <h3 className="mb-3">Summary</h3>
              <p>{summary}</p>
            </div>
          ) : (
            <div className="plan-panel-changes--summary mt-5 mb-5">
              <h3 className="mb-3">Summary</h3>
              <UISkeleton type="text" rows={3} />
            </div>
          )}
          <PlanPanelChangesDiff proposedChanges={changes?.planChange || {}} />
        </div>
      )}
    </div>
  );
};

export default PlanPanelChanges;
