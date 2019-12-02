import React from "react";
import PropTypes from "prop-types";
import UIAlert from "../../UI/Alert";
import { INGEST_SHEET_COMPLETED_ERRORS } from "../ingestSheet.query";
import { useQuery } from "@apollo/react-hooks";
import Error from "../../UI/Error";

const IngestSheetCompletedErrors = ({ ingestSheetId }) => {
  const { loading, error, data } = useQuery(
    INGEST_SHEET_COMPLETED_ERRORS,
    {
      variables: { id: ingestSheetId }
    }
  );

  if (loading) return "Loading...";
  if (error) return <Error error={error} />;

  const fileSets = data.ingestSheetErrors;
  const errorBody = (
    <table className="w-full clear">
      <thead>
        <tr>
          <th>Row</th>
          <th>Work Accession Number</th>
          <th>Accession Number</th>
          <th>Filename</th>
          <th>Action</th>
          <th>Errors</th>
        </tr>
      </thead>
      <tbody>
        {fileSets.map(row => {
          var errorMsg = row.outcome == 'SKIPPED' ? "Skipped due to error(s) on other row(s)" : row.errors;
          return (
            <tr key={row.rowNumber}>
              <td>{row.rowNumber}</td>
              <td>{row.workAccessionNumber}</td>
              <td>{row.accessionNumber}</td>
              <td>{row.filename}</td>
              <td>{row.action.split('.').slice(-1).pop()}</td>
              <td>{errorMsg}</td>
              <td></td>
            </tr>
          )
        })}
      </tbody>
    </table>
  );
console.log(errorBody);
  return (
    <UIAlert
      title="Errors creating works from filesets"
      type="danger"
      body={errorBody}
    />
  );
};

IngestSheetCompletedErrors.propTypes = {
  ingestSheetId: PropTypes.string
};

export default IngestSheetCompletedErrors;
