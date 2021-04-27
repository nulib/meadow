import React from "react";
import PropTypes from "prop-types";
import { IconAlert } from "@js/components/Icon";
import IconText from "@js/components/UI/IconText";

const styles = {
  tableWrapper: {
    height: "500px",
    overflowY: "auto",
    border: "1px solid #efefef",
  },
};

const IngestSheetCompletedErrors = ({ errors = [] }) => {
  return (
    <>
      <p className="notification is-danger is-light">
        <IconText isCentered icon={<IconAlert />}>
          Errors occurred during ingest
        </IconText>
      </p>
      <div style={styles.tableWrapper} className="table-container">
        <table className="table is-fullwidth is-striped">
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
            {errors.map((row, i) => {
              var errorMsg =
                row.outcome == "SKIPPED"
                  ? "Skipped due to error(s) on other row(s)"
                  : row.errors;
              return (
                <tr key={i}>
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
