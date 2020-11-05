import React, { useEffect } from "react";
import IngestSheetValidations from "./Validations";
import PropTypes from "prop-types";
import IngestSheetApprovedInProgress from "./ApprovedInProgress";
import IngestSheetCompleted from "./Completed";
import {
  INGEST_SHEET_SUBSCRIPTION,
} from "@js/components/IngestSheet/ingestSheet.gql";

const IngestSheet = ({ ingestSheetData, subscribeToIngestSheetUpdates }) => {
  const { id, status, title } = ingestSheetData;

  useEffect(() => {
    subscribeToIngestSheetUpdates({
      document: INGEST_SHEET_SUBSCRIPTION,
      variables: { sheetId: id },
      updateQuery: (prev, { subscriptionData }) => {
        if (!subscriptionData.data) return prev;
        return {
          ingestSheet: {
            ...subscriptionData.data.ingestSheetUpdate,
          },
        };
      },
    });
  }, []);


  const isCompleted = status === "COMPLETED";

  return (
    <div className="box">
        <>
          {["APPROVED"].indexOf(status) > -1 && (
            <IngestSheetApprovedInProgress ingestSheet={ingestSheetData} />
          )}

          {isCompleted && (
            <IngestSheetCompleted sheetId={ingestSheetData.id} title={title} />
          )}

          {["VALID", "ROW_FAIL", "FILE_FAIL", "UPLOADED"].indexOf(status) >
            -1 && (
            <IngestSheetValidations sheetId={id} status={status} />
          )}
        </>
    </div>
  );
};

IngestSheet.propTypes = {
  ingestSheetData: PropTypes.object,
  projectId: PropTypes.string,
  subscribeToIngestSheetUpdates: PropTypes.func,
};

export default IngestSheet;
