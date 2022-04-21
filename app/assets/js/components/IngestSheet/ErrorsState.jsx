import React from "react";
import PropTypes from "prop-types";

const IngestSheetErrorsState = ({ rows }) => {
  const rowHasErrors = (object) =>
    object && object.errors && object.errors.length > 0;
  return (
    <div className="table-container">
      <table className="table is-striped is-hoverable is-fullwidth">
        <caption>Ingest sheet validation row errors</caption>
        <thead>
          <tr>
            <th>Row #</th>
            <th>Status</th>
            <th>Content</th>
            <th>Errors</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((object) => (
            <tr key={object.row}>
              <td>{object && object.row}</td>
              <td>
                <span className="tag is-danger">{object && object.state}</span>
              </td>
              <td>
                {object && object.fields.map((field) => field.value).join("; ")}
              </td>
              <td>
                {rowHasErrors(object)
                  ? object.errors
                      .map(({ _field, message }, index) => message)
                      .join(", ")
                  : ""}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

IngestSheetErrorsState.propTypes = {
  rows: PropTypes.arrayOf(PropTypes.object),
};

export default IngestSheetErrorsState;
