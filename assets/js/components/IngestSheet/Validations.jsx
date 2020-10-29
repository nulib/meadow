import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import UIProgressBar from "../UI/UIProgressBar";
import debounce from "lodash.debounce";
import IngestSheetReport from "./Report";
import {
  INGEST_SHEET_VALIDATION_PROGRESS_SUBSCRIPTION,
  START_VALIDATION,
} from "./ingestSheet.gql";
import { useMutation } from "@apollo/client";

function IngestSheetValidations({
  percentComplete,
  sheetId,
  subscribeToIngestSheetValidationProgress,
  status,
}) {
  const [startValidation, { validationData }] = useMutation(START_VALIDATION);
  const isValidating = status === "UPLOADED";
  console.log("\nIngestSheetValidations() percentComplete", percentComplete);

  useEffect(() => {
    subscribeToIngestSheetValidationProgress({
      document: INGEST_SHEET_VALIDATION_PROGRESS_SUBSCRIPTION,
      variables: { sheetId },
      updateQuery: debounce(handleProgressUpdate, 250, { maxWait: 250 }),
    });
    startValidation({ variables: { id: sheetId } });
  }, []);

  // This function handles fresh data from the subscription, which
  // updates the "ingestSheetValidationProgress" query used in the parent component,
  // which in turn feeds data back into this component
  const handleProgressUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;
    return {
      ingestSheetValidationProgress:
        subscriptionData.data.ingestSheetValidationProgress.percentComplete,
    };
  };

  return (
    <section>
      {isValidating ? (
        <UIProgressBar
          percentComplete={Number(percentComplete)}
          label="Please wait for validation"
        />
      ) : (
        <IngestSheetReport status={status} sheetId={sheetId} />
      )}
    </section>
  );
}

IngestSheetValidations.propTypes = {
  percentComplete: PropTypes.number,
  sheetId: PropTypes.string.isRequired,
  status: PropTypes.oneOf([
    "APPROVED",
    "COMPLETED",
    "DELETED",
    "FILE_FAIL",
    "ROW_FAIL",
    "UPLOADED",
    "VALID",
  ]),
  subscribeToIngestSheetValidationProgress: PropTypes.func,
};

export default IngestSheetValidations;
