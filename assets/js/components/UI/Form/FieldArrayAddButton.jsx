import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import { IconAdd } from "@js/components/Icon";

function FieldArrayAddButton({ btnLabel, handleAddClick }) {
  return (
    <Button
      isLight
      onClick={handleAddClick}
      data-testid="button-add-field-array-row"
      className="mb-2"
    >
      <IconAdd />
      <span>{btnLabel}</span>
    </Button>
  );
}

FieldArrayAddButton.propTypes = {
  btnLabel: PropTypes.string,
  handleAddClick: PropTypes.func,
};

export default FieldArrayAddButton;
