import React from "react";
import UIProgressBar from "../UI/UIProgressBar";
import PropTypes from "prop-types";
import { useSubscription } from "@apollo/client";
import { INGEST_PROGRESS_SUBSCRIPTION } from "./ingestSheet.gql";

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
      <p className="notification is-danger is-light">
        Error in Ingest Progress Subscription: {error.message}
      </p>
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
