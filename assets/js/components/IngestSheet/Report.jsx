import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import Error from "../UI/Error";
import IngestSheetErrorsState from "./ErrorsState";
import IngestSheetUnapprovedState from "./UnapprovedState";
import {
  GET_INGEST_SHEET_ROW_VALIDATION_ERRORS,
  GET_INGEST_SHEET_ROW_VALIDATIONS,
} from "./ingestSheet.gql";
import UISkeleton from "@js/components/UI/Skeleton";

function IngestSheetReport({ sheetId, status }) {
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

  if (loading) return <UISkeleton rows={15} />;
  if (error) return <Error error={error} />;

  // Render Errors table
  if (sheetHasErrors()) {
    return <IngestSheetErrorsState validations={data.ingestSheetRows} />;
  }

  // By default render valid Work groupings
  return <IngestSheetUnapprovedState validations={data.ingestSheetRows} />;
}

IngestSheetReport.propTypes = {
  sheetId: PropTypes.string.isRequired,
  status: PropTypes.string,
};

export default IngestSheetReport;
