import React, { useEffect } from "react";
import { useQuery } from "@apollo/client";
import Error from "../UI/Error";
import UISkeleton from "../UI/Skeleton";
import IngestSheetValidations from "./Validations";
import { GET_INGEST_SHEET_VALIDATION_PROGRESS } from "./ingestSheet.gql";
import PropTypes from "prop-types";
import IngestSheetApprovedInProgress from "./ApprovedInProgress";
import IngestSheetCompleted from "./Completed";

const IngestSheet = ({ ingestSheetData, subscribeToIngestSheetUpdates }) => {
  const { id, status, title } = ingestSheetData;

  const {
    data,
    loading,
    error,
    subscribeToMore: validationProgressSubscribeToMore,
  } = useQuery(GET_INGEST_SHEET_VALIDATION_PROGRESS, {
    variables: { sheetId: id },
    fetchPolicy: "network-only",
  });

  console.log("\ndata", data);

  useEffect(() => {
    subscribeToIngestSheetUpdates();
  }, []);

  if (error) return <Error error={error} />;

  const isCompleted = status === "COMPLETED";

  return (
    <div className="box">
      {loading ? (
        <UISkeleton rows={15} />
      ) : (
        <>
          <h2 className={`title is-size-5 ${isCompleted ? "is-hidden" : ""}`}>
            Ingest Sheet Contents
          </h2>

          {["APPROVED"].indexOf(status) > -1 && (
            <IngestSheetApprovedInProgress ingestSheet={ingestSheetData} />
          )}

          {isCompleted && (
            <IngestSheetCompleted sheetId={ingestSheetData.id} title={title} />
          )}

          {["VALID", "ROW_FAIL", "FILE_FAIL", "UPLOADED"].indexOf(status) >
            -1 && (
            <IngestSheetValidations
              sheetId={id}
              status={status}
              percentComplete={
                data.ingestSheetValidationProgress.percentComplete
              }
              subscribeToIngestSheetValidationProgress={
                validationProgressSubscribeToMore
              }
            />
          )}
        </>
      )}
    </div>
  );
};

IngestSheet.propTypes = {
  ingestSheetData: PropTypes.object,
  projectId: PropTypes.string,
  subscribeToIngestSheetUpdates: PropTypes.func,
};

export default IngestSheet;
