import React from "react";
import UIFormField from "../UI/Form/Field";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import PropTypes from "prop-types";

export default function BatchEditRemove({ handleRemoveClick, label, name }) {
  return (
    <fieldset className="remove" data-testid="batch-edit-remove">
      <legend data-testid="legend-label">{label} (Remove)</legend>
      <UIFormField>
        <button
          data-testid="button-remove"
          type="button"
          className="button is-text is-small"
          onClick={() => handleRemoveClick({ label, name })}
        >
          <span className="icon">
            <FontAwesomeIcon icon="minus-square" />
          </span>
          <span>Remove</span>
        </button>
      </UIFormField>
    </fieldset>
  );
}

BatchEditRemove.propTypes = {
  handleRemoveClick: PropTypes.func,
  label: PropTypes.string,
  name: PropTypes.string,
};
