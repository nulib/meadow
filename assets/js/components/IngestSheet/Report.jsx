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

function IngestSheetReport({ ingestSheetId, progress, sheetState }) {
  const sheetHasErrors = () => {
    if (sheetState.find(({ state }) => state == "FAIL")) {
      return true;
    }
    const fails = progress.states.find(({ state }) => state == "FAIL");
    return fails && fails.count > 0;
  };

  const { loading, error, data } = useQuery(
    sheetHasErrors() ? GET_INGEST_SHEET_ERRORS : GET_INGEST_SHEET_VALIDATIONS,
    {
      variables: { ingestSheetId },
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
  ingestSheetId: PropTypes.string.isRequired,
  progress: PropTypes.object.isRequired,
  sheetState: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default IngestSheetReport;
