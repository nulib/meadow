import React, { useEffect } from "react";
import IngestSheetValidations from "./Validations";
import PropTypes from "prop-types";
import IngestSheetApprovedInProgress from "./ApprovedInProgress";
import IngestSheetCompleted from "./Completed";
import { INGEST_SHEET_SUBSCRIPTION } from "@js/components/IngestSheet/ingestSheet.gql";

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

  const isCompleted = ["COMPLETED", "COMPLETED_ERROR"].indexOf(status) > -1;

  return (
    <>
      {["APPROVED"].indexOf(status) > -1 && (
        <div className="box">
          <IngestSheetApprovedInProgress ingestSheet={ingestSheetData} />
        </div>
      )}

      {isCompleted && (
        <>
          <IngestSheetCompleted sheetId={ingestSheetData.id} title={title} />
        </>
      )}

      {["ROW_FAIL", "FILE_FAIL", "UPLOADED"].indexOf(status) > -1 && (
        <div className="box">
          <IngestSheetValidations sheetId={id} status={status} />
        </div>
      )}
    </>
  );
};

IngestSheet.propTypes = {
  ingestSheetData: PropTypes.object,
  projectId: PropTypes.string,
  subscribeToIngestSheetUpdates: PropTypes.func,
};

export default IngestSheet;
