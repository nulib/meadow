import React from "react";
import UIFormField from "../UI/Form/Field";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import PropTypes from "prop-types";
import { splitFacetKey } from "../../services/metadata";
import { useBatchDispatch } from "../../context/batch-edit-context";

export default function BatchEditRemove({
  handleRemoveClick,
  label,
  name,
  removeItems,
}) {
  const dispatch = useBatchDispatch();

  const removeFromDelete = (e, item) => {
    e.preventDefault();
    dispatch({
      type: "updateRemoveItem",
      fieldName: name,
      key: item,
    });
  };
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
        <div className="content has-background-danger-light">
          <ul className="py-4">
            {removeItems.map((item) => {
              const { label, role, term } = splitFacetKey(item);
              return (
                <li key={item}>
                  {`${label} - ${term}`}
                  <span
                    className="is-pulled-right icon mr-2"
                    onClick={(e) => removeFromDelete(e, item)}
                    data-testid="remove-delete-entries"
                  >
                    {<FontAwesomeIcon icon="trash" />}
                  </span>
                </li>
              );
            })}
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
