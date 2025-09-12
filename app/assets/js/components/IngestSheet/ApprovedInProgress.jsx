import React from "react";
import UIProgressBar from "../UI/UIProgressBar";
import PropTypes from "prop-types";
import { useSubscription } from "@apollo/client/react";
import { INGEST_PROGRESS_SUBSCRIPTION } from "./ingestSheet.gql";
import { Notification } from "@nulib/design-system";

const IngestSheetApprovedInProgress = ({ ingestSheet }) => {
  const { data, loading, error } = useSubscription(
    INGEST_PROGRESS_SUBSCRIPTION,
    {
      variables: { sheetId: ingestSheet.id },
    }
  );

  if (loading) return null;
  if (error) {
    console.error(error);
    return (
      <Notification isDanger>
        Error in Ingest Progress Subscription: {error.message}
      </Notification>
    );
  }

  return (
    <UIProgressBar
      percentComplete={Number(data.ingestProgress.percentComplete)}
      totalValue={data.ingestProgress.totalFileSets}
      isIngest={true}
    />
  );
};

IngestSheetApprovedInProgress.propTypes = {
  ingestSheet: PropTypes.object,
};

export default IngestSheetApprovedInProgress;
