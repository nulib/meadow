import React, { useEffect } from "react";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import IngestSheetValidations from "./Validations";
import {
  GET_INGEST_SHEET_STATE,
  GET_INGEST_SHEET_PROGRESS
} from "./ingestSheet.query";
import IngestSheetAlert from "./Alert";
import PropTypes from "prop-types";
import IngestSheetActionRow from "./ActionRow";

/**
 * The following are possible status values for an Ingest Sheet)
 *

APPROVED: Approved, ingest in progress
COMPLETED: Ingest Completed
DELETED: Ingest Sheet deleted
FILE_FAIL: Errors validating csv file
ROW_FAIL: Errors in content rows
UPLOADED: Uploaded, validation in progress
VALID: Passes validation
*/

const IngestSheet = ({
  ingestSheetData,
  projectId,
  subscribeToIngestSheetUpdates
}) => {
  const { id, status } = ingestSheetData;
  console.log("TCL: ingestSheetData", ingestSheetData);
  console.log("TCL: status", status);

  const {
    data: stateData,
    loading: stateLoading,
    error: stateError,
    subscribeToMore: stateSubscribeToMore
  } = useQuery(GET_INGEST_SHEET_STATE, {
    variables: { ingestSheetId: id },
    fetchPolicy: "network-only"
  });
  console.log("TCL: stateData", stateData);

  const {
    data: progressData,
    loading: progressLoading,
    error: progressError,
    subscribeToMore: progressSubscribeToMore
  } = useQuery(GET_INGEST_SHEET_PROGRESS, {
    variables: { ingestSheetId: id },
    fetchPolicy: "network-only"
  });
  console.log("TCL: progressData", progressData);

  useEffect(() => {
    subscribeToIngestSheetUpdates();
  }, []);

  if (stateLoading || progressLoading) return <Loading />;
  if (stateError || progressError) {
    return <Error error={stateError ? stateError : progressError} />;
  }

  return (
    <>
      <IngestSheetAlert ingestSheet={ingestSheetData} />

      <IngestSheetActionRow
        ingestSheetId={id}
        projectId={projectId}
        status={status}
      />

      <IngestSheetValidations
        ingestSheetId={id}
        initialProgress={progressData.ingestSheetProgress}
        initialStatus={stateData.ingestSheet.state}
        subscribeToIngestSheetProgress={progressSubscribeToMore}
        subscribeToIngestSheetState={stateSubscribeToMore}
      />
    </>
  );
};

IngestSheet.propTypes = {
  ingestSheetData: PropTypes.object,
  projectId: PropTypes.string,
  subscribeToIngestSheetUpdates: PropTypes.func
};

export default IngestSheet;
