import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import IngestSheetErrorsState from "./ErrorsState";
import IngestSheetUnapprovedState from "./UnapprovedState";
import {
  GET_INGEST_SHEET_ROW_VALIDATION_ERRORS,
  GET_INGEST_SHEET_ROW_VALIDATIONS,
} from "./ingestSheet.gql";

function IngestSheetReport({ sheetId, progress, status }) {
  const sheetHasErrors = () => {
    return ["FILE_FAIL", "ROW_FAIL"].indexOf(status) > -1;
  };

  const { loading, error, data } = useQuery(
    sheetHasErrors()
      ? GET_INGEST_SHEET_ROW_VALIDATION_ERRORS
      : GET_INGEST_SHEET_ROW_VALIDATIONS,
    {
      variables: { sheetId, limit: 100 },
      fetchPolicy: "network-only",
    }
  );

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const ingestSheetRows = data.ingestSheetRows;

  // Validation is still running, so keep table hidden
  if (status === "UPLOADED") {
    return null;
  }

  // Render Errors table
  if (sheetHasErrors()) {
    return <IngestSheetErrorsState validations={ingestSheetRows} />;
  }

  // By default render valid Work groupings
  return <IngestSheetUnapprovedState validations={ingestSheetRows} />;
}

IngestSheetReport.propTypes = {
  sheetId: PropTypes.string.isRequired,
  progress: PropTypes.object.isRequired,
  status: PropTypes.string,
};

export default IngestSheetReport;
