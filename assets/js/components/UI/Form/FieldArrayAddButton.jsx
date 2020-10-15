import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

function FieldArrayAddButton({ btnLabel, handleAddClick }) {
  return (
    <button
      type="button"
      className="button is-text is-small"
      onClick={handleAddClick}
      data-testid="button-add-field-array-row"
    >
      <span className="icon">
        <FontAwesomeIcon icon="plus" />
      </span>
      <span>{btnLabel}</span>
    </button>
  );
}

FieldArrayAddButton.propTypes = {
  btnLabel: PropTypes.string,
  handleAddClick: PropTypes.func,
};

export default FieldArrayAddButton;
