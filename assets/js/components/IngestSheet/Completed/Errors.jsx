import React from "react";
import PropTypes from "prop-types";

const styles = {
  tableWrapper: {
    height: "500px",
    overflowY: "auto",
  },
};

const IngestSheetCompletedErrors = ({ errors = [] }) => {
  return (
    <>
      <p className="notification is-danger">
        There were errors creating works from filesets
      </p>
      <div className="box" style={styles.tableWrapper}>
        <table className="table is-fullwidth is-striped">
          <caption>Errors creating works</caption>
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
            {errors.map((row) => {
              var errorMsg =
                row.outcome == "SKIPPED"
                  ? "Skipped due to error(s) on other row(s)"
                  : row.errors;
              return (
                <tr key={row.rowNumber}>
                  <td>{row.rowNumber}</td>
                  <td>{row.workAccessionNumber}</td>
                  <td>{row.accessionNumber}</td>
                  <td>{row.filename}</td>
                  <td>{row.action.split(".").slice(-1).pop()}</td>
                  <td>{errorMsg}</td>
                  <td></td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </>
  );
};

IngestSheetCompletedErrors.propTypes = {
  errors: PropTypes.array,
};

export default IngestSheetCompletedErrors;
