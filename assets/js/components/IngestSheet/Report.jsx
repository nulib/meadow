import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import Error from "../UI/Error";
import IngestSheetErrorsState from "./ErrorsState";
import IngestSheetUnapprovedState from "./UnapprovedState";
import { GET_INGEST_SHEET_ROWS } from "./ingestSheet.gql";
import UISkeleton from "@js/components/UI/Skeleton";

function IngestSheetReport({ sheetId, status }) {
  const hasErrors = ["FILE_FAIL", "ROW_FAIL"].indexOf(status) > -1;

  const ingestSheetQueryVars = {
    sheetId,
    limit: 100,
    state: hasErrors ? "FAIL" : "PASS",
  };

  const { loading, error, data } = useQuery(GET_INGEST_SHEET_ROWS, {
    variables: ingestSheetQueryVars,
    fetchPolicy: "network-only",
  });

  console.log("data", data);

  if (loading) return <UISkeleton rows={15} />;
  if (error) return <Error error={error} />;

  const { ingestSheetRows } = data;

  return (
    <>
      {hasErrors ? (
        <IngestSheetErrorsState rows={ingestSheetRows} />
      ) : (
        <IngestSheetUnapprovedState rows={ingestSheetRows} />
      )}
      <p className="notification is-italic">
        * Note: Work/Fileset preview is limited to 100 rows/filesets
      </p>
    </>
  );
}

IngestSheetReport.propTypes = {
  sheetId: PropTypes.string.isRequired,
  status: PropTypes.string,
};

export default IngestSheetReport;
