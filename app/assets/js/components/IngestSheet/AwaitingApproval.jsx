import React, { useState } from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/client/react";
import { START_VALIDATION } from "./ingestSheet.gql";
import IngestSheetUnapprovedState from "./UnapprovedState";
import { useQuery } from "@apollo/client/react";
import { INGEST_SHEET_ROWS } from "./ingestSheet.gql";
import UISkeleton from "@js/components/UI/Skeleton";
import Error from "@js/components/UI/Error";
import { Button, Notification } from "@nulib/design-system";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

function IngestSheetAwaitingApproval({ sheetId }) {
  const [understood, setUnderstood] = useState(false);
  const { isAuthorized } = useIsAuthorized();
  const canApprove = isAuthorized("SUPERMANAGER");

  const { loading, error, data } = useQuery(INGEST_SHEET_ROWS, {
    variables: { sheetId, limit: 100, state: "PASS" },
    fetchPolicy: "network-only",
    skip: !canApprove,
  });

  const [approveIngestSheet, { loading: approving }] = useMutation(
    START_VALIDATION,
    { variables: { id: sheetId } }
  );

  if (!canApprove) {
    return (
      <Notification>
        This AI ingest sheet is awaiting supermanager approval before ingesting.
      </Notification>
    );
  }

  if (loading) return <UISkeleton rows={15} />;
  if (error) return <Error error={error} />;

  return (
    <div>
      <Notification>
        This is an AI ingest sheet. Please review the work and fileset data
        below before approving.
      </Notification>

      {data && (
        <IngestSheetUnapprovedState rows={data.ingestSheetRows} />
      )}

      <div className="field mt-5">
        <label className="checkbox">
          <input
            type="checkbox"
            checked={understood}
            onChange={(e) => setUnderstood(e.target.checked)}
            className="mr-2"
          />
          I understand that approving this AI-generated ingest sheet will
          immediately begin ingesting the listed works and filesets.
        </label>
      </div>

      <div className="mt-4">
        <Button
          isPrimary
          disabled={!understood || approving}
          onClick={approveIngestSheet}
        >
          Approve and Start Ingest
        </Button>
      </div>
    </div>
  );
}

IngestSheetAwaitingApproval.propTypes = {
  sheetId: PropTypes.string.isRequired,
};

export default IngestSheetAwaitingApproval;
