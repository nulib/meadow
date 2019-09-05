import React from "react";
import PropTypes from "prop-types";

const InventorySheetErrorsState = ({ validations }) => {
  const rowHasErrors = object =>
    object && object.errors && object.errors.length > 0;
  return (
    <>
      <h2>Error report</h2>
      <table>
        <thead>
          <tr>
            <th>Row #</th>
            <th>Status</th>
            <th>Content</th>
            <th>Errors</th>
          </tr>
        </thead>
        <tbody>
          {validations.map(object => (
            <tr key={object.row}>
              <td>{object && object.row}</td>
              <td>{object && object.state}</td>
              <td>
                {object && object.fields.map(field => field.value).join("; ")}
              </td>
              <td>
                {rowHasErrors(object)
                  ? object.errors.map(({ _field, message }, index) => (
                      <span key={index}>{message}</span>
                    ))
                  : ""}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
};

InventorySheetErrorsState.propTypes = {
  validations: PropTypes.arrayOf(PropTypes.object)
};

export default InventorySheetErrorsState;
