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
    data: progressData,
    loading: progressLoading,
    error: progressError,
    subscribeToMore: progressSubscribeToMore,
  } = useQuery(GET_INGEST_SHEET_VALIDATION_PROGRESS, {
    variables: { sheetId: id },
    fetchPolicy: "network-only",
  });

  useEffect(() => {
    subscribeToIngestSheetUpdates();
  }, []);

  if (progressError) return <Error error={progressError} />;

  const isCompleted = status === "COMPLETED";

  return (
    <div className="box">
      {progressLoading ? (
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
                progressData.ingestSheetValidationProgress.percentComplete
              }
              subscribeToIngestSheetValidationProgress={progressSubscribeToMore}
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
