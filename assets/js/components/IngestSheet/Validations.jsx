import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import UIProgressBar from "../UI/UIProgressBar";
import debounce from "lodash.debounce";
import IngestSheetReport from "./Report";
import {
  SUBSCRIBE_TO_INGEST_SHEET_STATE,
  SUBSCRIBE_TO_INGEST_SHEET_PROGRESS
} from "./ingestSheet.query";
import { withRouter } from "react-router-dom";

function IngestSheetValidations({
  ingestSheetId,
  initialProgress,
  initialStatus,
  subscribeToIngestSheetProgress,
  subscribeToIngestSheetState
}) {
  const [progress, setProgress] = useState({ states: [] });
  const [status, setStatus] = useState([]);

  useEffect(() => {
    setProgress(initialProgress);
    subscribeToIngestSheetProgress({
      document: SUBSCRIBE_TO_INGEST_SHEET_PROGRESS,
      variables: { ingestSheetId },
      updateQuery: debounce(handleProgressUpdate, 250, { maxWait: 250 })
    });

    setStatus(initialStatus);
    subscribeToIngestSheetState({
      document: SUBSCRIBE_TO_INGEST_SHEET_STATE,
      variables: { ingestSheetId },
      updateQuery: handleStatusUpdate
    });
  }, []);

  const handleProgressUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const progress = subscriptionData.data.ingestSheetProgressUpdate;
    setProgress(progress);
    return { ingestSheetProgress: progress };
  };

  const handleStatusUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const status = subscriptionData.data.ingestSheetUpdate.state;
    setStatus(status);
    return { ingestSheet: subscriptionData.data.ingestSheetUpdate };
  };

  const isFinished = () => {
    return status.find(
      ({ name, state }) => name == "overall" && state != "PENDING"
    );
  };

  const showProgressBar = () => {
    if (isFinished()) {
      return null;
    }
    return (
      <UIProgressBar
        percentComplete={progress.percentComplete}
        label="Please wait for validation"
      />
    );
  };

  const showReport = () => {
    if (isFinished()) {
      return (
        <>
          <IngestSheetReport
            progress={progress}
            sheetState={status}
            ingestSheetId={ingestSheetId}
          />
        </>
      );
    } else {
      return <></>;
    }
  };

  return (
    <>
      <section>
        {showProgressBar()}
        {showReport()}
      </section>
    </>
  );
}

IngestSheetValidations.propTypes = {
  ingestSheetId: PropTypes.string.isRequired,
  initialProgress: PropTypes.object.isRequired,
  initialStatus: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default withRouter(IngestSheetValidations);
