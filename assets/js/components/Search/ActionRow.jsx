import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";

export default function SearchActionRow({
  handleDeselectAll,
  handleEditAllItems,
  handleViewAndEdit,
  numberOfResults,
  selectedItems = [],
}) {
  return (
    <div className="field is-grouped" data-testid="search-action-row">
      <p className="control">
        <Button
          isLight
          onClick={handleEditAllItems}
          disabled={selectedItems.length > 0}
          data-testid="edit-all-button"
        >
          <span className="icon">
            <FontAwesomeIcon icon="edit" />
          </span>
          <span>Edit All {numberOfResults} Items</span>
        </Button>
      </p>
      <p className="control">
        <Button
          isLight
          data-testid="view-and-edit-button"
          disabled={selectedItems.length === 0}
          onClick={handleViewAndEdit}
        >
          <span className="icon">
            <FontAwesomeIcon icon="eye" />
          </span>
          <span>View and Edit {selectedItems.length} Items</span>
        </Button>
      </p>
      {selectedItems.length > 0 && (
        <p className="control">
          <Button
            isLight
            data-testid="deselect-all-button"
            onClick={handleDeselectAll}
          >
            <span className="icon">
              <FontAwesomeIcon icon="minus-square" />
            </span>
            <span>Deselect All</span>
          </Button>
        </p>
      )}
      <p className="control">
        <Button isLight disabled>
          <span className="icon">
            <FontAwesomeIcon icon="file-csv" />
          </span>
          <span>Export CSV</span>
        </Button>
      </p>
    </div>
  );
}

SearchActionRow.propTypes = {
  handleDeselectAll: PropTypes.func,
  handleEditAllItems: PropTypes.func.isRequired,
  handleViewAndEdit: PropTypes.func.isRequired,
  numberOfResults: PropTypes.number,
  selectedItems: PropTypes.array,
};
