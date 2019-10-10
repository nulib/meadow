import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import UIProgressBar from "../UI/UIProgressBar";
import debounce from "lodash.debounce";
import IngestSheetReport from "./Report";
import {
  SUBSCRIBE_TO_INGEST_SHEET_PROGRESS,
  START_VALIDATION
} from "./ingestSheet.query";
import { withRouter } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";

function IngestSheetValidations({
  ingestSheetId,
  initialProgress,
  subscribeToIngestSheetProgress,
  status
}) {
  const [progress, setProgress] = useState({ states: [] });
  const [startValidation, { validationData }] = useMutation(START_VALIDATION);

  useEffect(() => {
    setProgress(initialProgress);
    subscribeToIngestSheetProgress({
      document: SUBSCRIBE_TO_INGEST_SHEET_PROGRESS,
      variables: { ingestSheetId },
      updateQuery: debounce(handleProgressUpdate, 250, { maxWait: 250 })
    });

    startValidation({ variables: { id: ingestSheetId } });
  }, []);

  const handleProgressUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const progress = subscriptionData.data.ingestSheetProgressUpdate;
    setProgress(progress);
    return { ingestSheetProgress: progress };
  };

  const isFinished = () => {
    return status !== "UPLOADED";
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
            status={status}
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
  status: PropTypes.oneOf([
    "APPROVED",
    "COMPLETED",
    "DELETED",
    "FILE_FAIL",
    "ROW_FAIL",
    "UPLOADED",
    "VALID"
  ]),
  initialProgress: PropTypes.object.isRequired
};

export default withRouter(IngestSheetValidations);
