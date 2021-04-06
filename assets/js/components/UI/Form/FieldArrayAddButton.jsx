import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";
import { IconAdd } from "@js/components/Icon";

function FieldArrayAddButton({ btnLabel, handleAddClick }) {
  return (
    <Button
      isLight
      onClick={handleAddClick}
      data-testid="button-add-field-array-row"
      className="mb-2"
    >
      <span className="icon">
        <IconAdd />
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
