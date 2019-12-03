import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import IngestSheetErrorsState from "./ErrorsState";
import IngestSheetUnapprovedState from "./UnapprovedState";
import {
  GET_INGEST_SHEET_ERRORS,
  GET_INGEST_SHEET_VALIDATIONS
} from "./ingestSheet.query";

function IngestSheetReport({ sheetId, progress, status }) {
  const sheetHasErrors = () => {
    return ["FILE_FAIL", "ROW_FAIL"].indexOf(status) > -1;
  };

  const { loading, error, data } = useQuery(
    sheetHasErrors() ? GET_INGEST_SHEET_ERRORS : GET_INGEST_SHEET_VALIDATIONS,
    {
      variables: { sheetId },
      fetchPolicy: "network-only"
    }
  );

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const ingestSheetRows = data.ingestSheetRows;

  {
    /* Don't show if sheet isn't complete */
  }
  if (progress.percentComplete === 0) {
    return null;
  }

  if (sheetHasErrors()) {
    return <IngestSheetErrorsState validations={ingestSheetRows} />;
  } else {
    return (
      <>
        <IngestSheetUnapprovedState validations={ingestSheetRows} />
      </>
    );
  }
}

IngestSheetReport.propTypes = {
  sheetId: PropTypes.string.isRequired,
  progress: PropTypes.object.isRequired,
  status: PropTypes.string
};

export default IngestSheetReport;
