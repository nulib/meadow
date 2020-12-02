import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";
import SearchBatchModal from "@js/components/Search/BatchModal";

export default function SearchActionRow({
  handleCsvExport,
  handleDeselectAll,
  handleEditAllItems,
  handleViewAndEdit,
  numberOfResults,
  selectedItems = [],
}) {
  const [isModalOpen, setIsModalOpen] = React.useState(false);

  return (
    <React.Fragment>
      <div className="field is-grouped" data-testid="search-action-row">
        <p className="control">
          <Button
            isLight
            onClick={() => setIsModalOpen(!isModalOpen)}
            disabled={selectedItems.length > 0}
            data-testid="select-all-button"
          >
            <span>Select All</span>
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
            <span>View and edit {selectedItems.length} Items</span>
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
              <span>Deselect all</span>
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
      <SearchBatchModal
        handleCloseClick={() => setIsModalOpen(false)}
        handleCsvExport={handleCsvExport}
        handleEditAllItems={handleEditAllItems}
        isOpen={isModalOpen}
        numberOfResults={numberOfResults}
      />
    </React.Fragment>
  );
}

SearchActionRow.propTypes = {
  handleCsvExport: PropTypes.func.isRequired,
  handleDeselectAll: PropTypes.func,
  handleEditAllItems: PropTypes.func.isRequired,
  handleViewAndEdit: PropTypes.func.isRequired,
  numberOfResults: PropTypes.number,
  selectedItems: PropTypes.array,
};
