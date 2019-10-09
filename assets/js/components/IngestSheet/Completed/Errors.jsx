import React from "react";
import PropTypes from "prop-types";
import UIAlert from "../../UI/Alert";
import { MOCK_INGEST_SHEET_COMPLETED_ERRORS } from "../ingestSheet.query";
import { useQuery } from "@apollo/react-hooks";
import Error from "../../UI/Error";

const IngestSheetCompletedErrors = ({ ingestSheetId }) => {
  const { loading, error, data } = useQuery(
    MOCK_INGEST_SHEET_COMPLETED_ERRORS,
    {
      variables: { id: ingestSheetId }
    }
  );

  if (loading) return "Loading...";
  if (error) return <Error error={error} />;

  const { fileSets } = data.mockIngestSheetErrors;
  const errorBody = (
    <table className="w-full clear">
      <thead>
        <tr>
          <th>Row</th>
          <th>Work Accession Number</th>
          <th>Accession Number</th>
          <th>Filename</th>
          <th>Errors</th>
        </tr>
      </thead>
      <tbody>
        {fileSets.map(row => (
          <tr key={row.rowNumber}>
            <td>{row.rowNumber}</td>
            <td>{row.workAccessionNumber}</td>
            <td>{row.accessionNumber}</td>
            <td>{row.filename}</td>
            <td>
              {row.errors.map(error => (
                <p key={error}>{error}</p>
              ))}
            </td>
            <td></td>
          </tr>
        ))}
      </tbody>
    </table>
  );

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
