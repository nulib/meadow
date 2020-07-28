import React from "react";
import PropTypes from "prop-types";

export default function SearchActionRow({
  handleEditAllItems,
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
          Edit All Items
        </button>
      </p>
      <p className="control">
        <button
          className="button is-light"
          disabled={selectedItems.length === 0}
        >
          View and Edit {selectedItems.length} Items
        </button>
      </p>
      <p className="control">
        <button className="button is-light">Deselect All (not wired up)</button>
      </p>
    </div>
  );
}

SearchActionRow.propTypes = {
  handleEditAllItems: PropTypes.func,
  selectedItems: PropTypes.array,
};
