import React from "react";
import PropTypes from "prop-types";
import ButtonGroup from "../../components/UI/ButtonGroup";
import UIButton from "../../components/UI/Button";
import CloseIcon from "../../../css/fonts/zondicons/close.svg";

const InventorySheetErrorsState = ({ validations }) => {
  const rowHasErrors = object =>
    object && object.errors && object.errors.length > 0;
  return (
    <>
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
          {validations.map((object) => (
            <tr key={object.row} className={rowHasErrors(object) ? "error" : ""}>
              <td>{object && object.row}</td>
              <td>{object && object.state}</td>
              <td>{object && object.fields.map(field => field.value).join("; ")}</td>
              <td>
                {rowHasErrors(object)
                  ? object.errors.map(({_field, message}, index) => (
                      <span key={index}>{message}</span>
                    ))
                  : ""}
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      <ButtonGroup>
        <UIButton>
          <CloseIcon className="icon" />
          Delete job and re-upload inventory sheet
        </UIButton>
      </ButtonGroup>
    </>
  );
};

InventorySheetErrorsState.propTypes = {
  validations: PropTypes.arrayOf(PropTypes.object)
};

export default InventorySheetErrorsState;
