import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";
import SearchBatchModal from "@js/components/Search/BatchModal";

export default function SearchActionRow({
  handleCsvExportAllItems,
  handleCsvExportItems,
  handleDeselectAll,
  handleEditAllItems,
  handleEditItems,
  handleViewAndEdit,
  numberOfResults,
  selectedItems = [],
}) {
  const [isModalAllItemsOpen, setIsModalAllItemsOpen] = React.useState(false);
  const [isModalItemsOpen, setIsModalItemsOpen] = React.useState(false);
  const numSelectedItems = selectedItems.length;

  function handleCsvExportAllItemsClick() {
    setIsModalAllItemsOpen(false);
    handleCsvExportAllItems();
  }

  function handleCsvExportItemsClick() {
    setIsModalItemsOpen(false);
    handleCsvExportItems();
  }

  function handleEditAllItemsClick() {
    setIsModalAllItemsOpen(false);
    handleEditAllItems();
  }

  function handleEditItemsClick() {
    setIsModalItemsOpen(false);
    handleEditItems();
  }

  function handleViewAndEditClick() {
    setIsModalItemsOpen(false);
    handleViewAndEdit();
  }

  return (
    <React.Fragment>
      <div className="field is-grouped" data-testid="search-action-row">
        <p className="control">
          <Button
            isLight
            onClick={() => setIsModalAllItemsOpen(!isModalAllItemsOpen)}
            disabled={selectedItems.length > 0}
            data-testid="button-select-all"
          >
            <span>Select All</span>
          </Button>
        </p>
        <p className="control">
          <Button
            isLight
            data-testid="button-edit-items"
            disabled={selectedItems.length === 0}
            onClick={() => setIsModalItemsOpen(!isModalItemsOpen)}
          >
            <span>Edit {selectedItems.length} Items</span>
          </Button>
        </p>
        {selectedItems.length > 0 && (
          <p className="control">
            <Button
              isLight
              data-testid="button-deselect-all"
              onClick={handleDeselectAll}
            >
              <span className="icon">
                <FontAwesomeIcon icon="minus-square" />
              </span>
              <span>Deselect all</span>
            </Button>
          </p>
        )}
      </div>

      {/* Batch edit ALL items */}
      <SearchBatchModal
        handleCloseClick={() => setIsModalAllItemsOpen(false)}
        isOpen={isModalAllItemsOpen}
      >
        <Button
          className="is-fullwidth mb-4"
          data-testid="button-batch-all-edit"
          onClick={handleEditAllItemsClick}
        >
          <span className="icon">
            <FontAwesomeIcon icon="edit" />
          </span>
          <span>Batch edit {numberOfResults} works</span>
        </Button>
        <Button
          className="is-fullwidth"
          data-testid="button-csv-all-export"
          onClick={handleCsvExportAllItemsClick}
        >
          <span className="icon">
            <FontAwesomeIcon icon="file-csv" />
          </span>
          <span>Export metadata from {numberOfResults} works </span>
        </Button>
      </SearchBatchModal>

      {/* Batch edit selected items */}
      <SearchBatchModal
        handleCloseClick={() => setIsModalItemsOpen(false)}
        isOpen={isModalItemsOpen}
      >
        <Button
          className="is-fullwidth mb-4"
          data-testid="button-batch-items-edit"
          onClick={handleEditItemsClick}
        >
          <span className="icon">
            <FontAwesomeIcon icon="edit" />
          </span>
          <span>Batch edit {numSelectedItems} works</span>
        </Button>
        <Button
          className="is-fullwidth mb-4"
          data-testid="button-view-and-edit"
          onClick={handleViewAndEditClick}
        >
          <span className="icon">
            <FontAwesomeIcon icon="eye" />
          </span>
          <span>View and edit {numSelectedItems} individual works</span>
        </Button>
        <Button
          className="is-fullwidth"
          data-testid="button-csv-items-export"
          onClick={handleCsvExportItemsClick}
        >
          <span className="icon">
            <FontAwesomeIcon icon="file-csv" />
          </span>
          <span>Export metadata from {numSelectedItems} works </span>
        </Button>
      </SearchBatchModal>
    </React.Fragment>
  );
}

SearchActionRow.propTypes = {
  handleCsvExportAllItems: PropTypes.func.isRequired,
  handleCsvExportItems: PropTypes.func.isRequired,
  handleDeselectAll: PropTypes.func,
  handleEditAllItems: PropTypes.func.isRequired,
  handleEditItems: PropTypes.func.isRequired,
  handleViewAndEdit: PropTypes.func.isRequired,
  numberOfResults: PropTypes.number,
  selectedItems: PropTypes.array,
};
