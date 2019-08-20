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
            <th>Job Id</th>
            <th>Status</th>
            <th>Content</th>
            <th>Errors</th>
          </tr>
        </thead>
        <tbody>
          {validations.map(({ id, object }) => (
            <tr key={id} className={rowHasErrors(object) ? "error" : ""}>
              <td>{id}</td>
              <td>{object && object.status}</td>
              <td>{object && object.content}</td>
              <td>
                {rowHasErrors(object)
                  ? object.errors.map((error, index) => (
                      <span key={index}>{error}</span>
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
  validations: PropTypes.array
};

export default InventorySheetErrorsState;
