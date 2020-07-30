import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

export default function SearchActionRow({
  handleDeselectAll,
  handleEditAllItems,
  numberOfResults,
  selectedItems = [],
}) {
  return (
    <div className="field is-grouped">
      <p className="control">
        <button
          className="button is-light"
          onClick={handleEditAllItems}
          disabled={selectedItems.length > 0}
        >
          <span className="icon">
            <FontAwesomeIcon icon="edit" />
          </span>
          <span>Edit All {numberOfResults} Items</span>
        </button>
      </p>
      <p className="control">
        <button
          className="button is-light"
          disabled={selectedItems.length === 0}
        >
          <span className="icon">
            <FontAwesomeIcon icon="eye" />
          </span>
          <span>View and Edit {selectedItems.length} Items</span>
        </button>
      </p>
      {selectedItems.length > 0 && (
        <p className="control">
          <button className="button is-light" onClick={handleDeselectAll}>
            <span className="icon">
              <FontAwesomeIcon icon="minus-square" />
            </span>
            <span>Deselect All</span>
          </button>
        </p>
      )}
      <p className="control">
        <button className="button is-light" disabled>
          <span className="icon">
            <FontAwesomeIcon icon="file-csv" />
          </span>
          <span>Export CSV</span>
        </button>
      </p>
    </div>
  );
}

SearchActionRow.propTypes = {
  handleDeselectAll: PropTypes.func,
  handleEditAllItems: PropTypes.func,
  numberOfResults: PropTypes.number,
  selectedItems: PropTypes.array,
};
