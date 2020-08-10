import React from "react";
import UIFormField from "../UI/Form/Field";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import PropTypes from "prop-types";
import { formatControlledTermKey } from "../../services/helpers";

export default function BatchEditRemove({
  handleRemoveClick,
  label,
  name,
  removeItems,
}) {
  return (
    <div data-testid="batch-edit-remove">
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
          <span>Remove entries in {label}</span>
        </button>
      </UIFormField>

      {removeItems.length > 0 && (
        <div className="content">
          <ul>
            {removeItems.map((item) => (
              <li key={item} className="has-text-danger">
                {formatControlledTermKey(item)}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

BatchEditRemove.propTypes = {
  handleRemoveClick: PropTypes.func,
  label: PropTypes.string,
  name: PropTypes.string,
  removeItems: PropTypes.array,
};
