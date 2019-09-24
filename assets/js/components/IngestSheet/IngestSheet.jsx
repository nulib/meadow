import React from "react";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import IngestSheetValidations from "./Validations";
import {
  GET_INGEST_SHEET_STATUS,
  GET_INGEST_SHEET_PROGRESS
} from "./ingestSheet.query";
import PropTypes from "prop-types";

const IngestSheet = ({ ingestSheetId }) => {
  const {
    data: statusData,
    loading: statusLoading,
    error: statusError,
    subscribeToMore: statusSubscribeToMore
  } = useQuery(GET_INGEST_SHEET_STATUS, {
    variables: { ingestSheetId },
    fetchPolicy: "network-only"
  });

  const {
    data: progressData,
    loading: progressLoading,
    error: progressError,
    subscribeToMore: progressSubscribeToMore
  } = useQuery(GET_INGEST_SHEET_PROGRESS, {
    variables: { ingestSheetId },
    fetchPolicy: "network-only"
  });

  if (statusLoading || progressLoading) return <Loading />;
  if (statusError || progressError)
    return <Error error={statusError || progressError} />;

  return (
    <>
      <IngestSheetValidations
        ingestSheetId={ingestSheetId}
        initialProgress={progressData.ingestSheetProgress}
        initialStatus={statusData.ingestSheet.state}
        subscribeToIngestSheetProgress={progressSubscribeToMore}
        subscribeToIngestSheetStatus={statusSubscribeToMore}
      />
    </>
  );
};

IngestSheet.propTypes = {
  ingestSheetId: PropTypes.string.isRequired
};

export default IngestSheet;
