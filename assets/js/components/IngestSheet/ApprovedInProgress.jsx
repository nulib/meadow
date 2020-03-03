import React, { useEffect } from "react";
import UIProgressBar from "../UI/UIProgressBar";
import PropTypes from "prop-types";
import { useSubscription } from "@apollo/react-hooks";
import { INGEST_PROGRESS_SUBSCRIPTION } from "./ingestSheet.query";

const IngestSheetApprovedInProgress = ({ ingestSheet }) => {
  const { data, loading, error } = useSubscription(
    INGEST_PROGRESS_SUBSCRIPTION,
    {
      variables: { sheetId: ingestSheet.id }
    }
  );

  if (loading)
    return (
      <progress className="progress is-primary" max="100">
        30%
      </progress>
    );
  if (error) {
    console.log(error);
    return <p>Error: {error.message}</p>;
  }

  const { ingestProgress } = data;
  return (
    <UIProgressBar
      percentComplete={Number(ingestProgress.percentComplete)}
      totalValue={ingestProgress.totalFileSets}
    />
  );
};

IngestSheetApprovedInProgress.propTypes = {
  ingestSheet: PropTypes.object
};

export default IngestSheetApprovedInProgress;
