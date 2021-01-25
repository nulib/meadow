import React from "react";
import PropTypes from "prop-types";

function DashboardsCsvErrors({ errors = [] }) {
  return (
    <div className="content" data-testid="csv-job-errors">
      <hr />
      <h2 className="title is-size-4">Errors</h2>

      <table className="table" data-testid="csv-job-errors-table">
        <thead>
          <tr>
            <th>Row</th>
            <th>Errors</th>
          </tr>
        </thead>
        <tbody>
          {errors.map(({ row, errors: rowErrors }) => (
            <tr key={row} data-testid="csv-job-errors-row">
              <td>{row}</td>
              <td>
                <dl
                  style={{ columns: 3 }}
                  data-testid="csv-job-errors-messages"
                >
                  {rowErrors.map((rowError) => (
                    <span
                      key={rowError.field}
                      data-testid="csv-job-error-message"
                    >
                      <dt>{rowError.field}</dt>
                      <dd>{rowError.messages}</dd>
                    </span>
                  ))}
                </dl>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

DashboardsCsvErrors.propTypes = {
  errors: PropTypes.array,
};

export default DashboardsCsvErrors;
