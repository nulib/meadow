import React, { useEffect } from "react";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import IngestSheetValidations from "./Validations";
import { GET_INGEST_SHEET_VALIDATION_PROGRESS } from "./ingestSheet.query";
import IngestSheetAlert from "./Alert";
import PropTypes from "prop-types";
import IngestSheetActionRow from "./ActionRow";
import IngestSheetApprovedInProgress from "./ApprovedInProgress";
import IngestSheetCompleted from "./Completed";

/**
 * Note: This component is dependent on the GraphQL "IngestSheet" data type "status" property.
 * Refer to latest values to clarify this component's logic.
 */

const IngestSheet = ({
  ingestSheetData,
  projectId,
  subscribeToIngestSheetUpdates
}) => {
  const { id, status, name } = ingestSheetData;

  const {
    data: progressData,
    loading: progressLoading,
    error: progressError,
    subscribeToMore: progressSubscribeToMore
  } = useQuery(GET_INGEST_SHEET_VALIDATION_PROGRESS, {
    variables: { sheetId: id },
    fetchPolicy: "network-only"
  });

  useEffect(() => {
    subscribeToIngestSheetUpdates();
  }, []);

  if (progressLoading) return <Loading />;
  if (progressError) return <Error error={progressError} />;

  return (
    <>
      {["APPROVED"].indexOf(status) > -1 && (
        <section className="section">
          <div className="container">
            <IngestSheetAlert ingestSheet={ingestSheetData} />
            <IngestSheetApprovedInProgress ingestSheet={ingestSheetData} />
          </div>
        </section>
      )}

      {["COMPLETED"].indexOf(status) > -1 && (
        <>
          <IngestSheetCompleted sheetId={ingestSheetData.id} />
        </>
      )}

      {["VALID", "ROW_FAIL", "FILE_FAIL", "UPLOADED"].indexOf(status) > -1 && (
        <section className="section">
          <div className="container">
            <IngestSheetAlert ingestSheet={ingestSheetData} />
            <IngestSheetValidations
              sheetId={id}
              status={status}
              initialProgress={progressData.ingestSheetValidationProgress}
              subscribeToIngestSheetValidationProgress={progressSubscribeToMore}
            />
          </div>
        </section>
      )}
    </>
  );
};

IngestSheet.propTypes = {
  ingestSheetData: PropTypes.object,
  projectId: PropTypes.string,
  subscribeToIngestSheetUpdates: PropTypes.func
};

export default IngestSheet;
