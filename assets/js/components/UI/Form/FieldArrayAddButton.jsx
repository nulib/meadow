import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";

function FieldArrayAddButton({ btnLabel, handleAddClick }) {
  return (
    <Button
      isLight
      onClick={handleAddClick}
      data-testid="button-add-field-array-row"
    >
      <span className="icon">
        <FontAwesomeIcon icon="plus" />
      </span>
      <span>{btnLabel}</span>
    </Button>
  );
}

FieldArrayAddButton.propTypes = {
  btnLabel: PropTypes.string,
  handleAddClick: PropTypes.func,
};

export default FieldArrayAddButton;
