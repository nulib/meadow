import {
  IconCsv,
  IconEdit,
  IconMinus,
  IconTrashCan,
} from "@js/components/Icon";

import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import BatchDeleteConfirmationModal from "@js/components/Search/BatchDeleteConfirmationModal";
import { Button } from "@nulib/design-system";
import FormDownloadWrapper from "@js/components/UI/Form/DownloadWrapper";
import PropTypes from "prop-types";
import React from "react";
import SearchBatchModal from "@js/components/Search/BatchModal";
import { buildSelectedItemsQuery } from "@js/services/reactive-search";
const { inflect } = require("inflection");

function ModalButton({ children, icon, label, ...restProps }) {
  return (
    <Button {...restProps}>
      {icon}
      <span>{label}</span>
    </Button>
  );
}
export default function SearchActionRow({
  handleDeselectAll,
  handleEditAllItems,
  handleEditItems,
  handleViewAndEdit,
  numberOfResults,
  selectedItems = [],
  filteredQuery,
}) {
  const [isModalAllItemsOpen, setIsModalAllItemsOpen] = React.useState(false);
  const [isModalItemsOpen, setIsModalItemsOpen] = React.useState(false);
  const [
    isModalBatchDeleteConfirmationOpen,
    setIsModalBatchDeleteConfirmationOpen,
  ] = React.useState(false);
  const numSelectedItems = selectedItems.length;

  function handleDeleteAllItemsClick() {
    setIsModalAllItemsOpen(false);
    setIsModalBatchDeleteConfirmationOpen(true);
  }

  function handleDeleteItemsClick() {
    setIsModalItemsOpen(false);
    setIsModalBatchDeleteConfirmationOpen(true);
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
    <>
      <div className="field is-grouped mb-6" data-testid="search-action-row">
        <p className="control">
          <Button
            onClick={() => setIsModalAllItemsOpen(!isModalAllItemsOpen)}
            disabled={selectedItems.length > 0}
            data-testid="button-select-all"
          >
            <span>View bulk actions (all works)</span>
          </Button>
        </p>
        <p className="control">
          <Button
            data-testid="button-edit-items"
            disabled={selectedItems.length === 0}
            onClick={() => setIsModalItemsOpen(!isModalItemsOpen)}
          >
            <span>
              {selectedItems.length > 0
                ? `View bulk actions (${selectedItems.length} ${inflect(
                    "work",
                    selectedItems.length
                  )})`
                : "View bulk actions (selected works)"}
            </span>
          </Button>
        </p>
        {selectedItems.length > 0 && (
          <p className="control">
            <Button
              data-testid="button-deselect-all"
              onClick={handleDeselectAll}
            >
              <IconMinus />
              <span>Deselect all</span>
            </Button>
          </p>
        )}
      </div>

      {/* Process ALL items */}
      <SearchBatchModal
        handleCloseClick={() => setIsModalAllItemsOpen(false)}
        isOpen={isModalAllItemsOpen}
      >
        <div className="is-flex is-flex-direction-column is-align-items-center">
          <AuthDisplayAuthorized level="EDITOR">
            <>
              <div className="block">
                <ModalButton
                  icon={<IconEdit />}
                  label={`Batch edit ${numberOfResults} ${inflect(
                    "work",
                    numberOfResults
                  )}`}
                  data-testid="button-batch-all-edit"
                  onClick={handleEditAllItemsClick}
                />
              </div>
              <FormDownloadWrapper
                formAction="/api/export/all_items.csv"
                queryValue={filteredQuery}
              >
                <ModalButton
                  icon={<IconCsv />}
                  label={`Export metadata from ${numberOfResults} ${inflect(
                    "work",
                    numberOfResults
                  )}`}
                  data-testid="button-csv-all-export"
                  type="submit"
                />
              </FormDownloadWrapper>
              <FormDownloadWrapper
                formAction="/api/create_shared_links/all_items.csv"
                queryValue={filteredQuery}
              >
                <ModalButton
                  icon={<IconCsv />}
                  label={`Download shared links for ${numberOfResults} ${inflect(
                    "work",
                    numberOfResults
                  )}`}
                  data-testid="button-csv-all-shared-links"
                  type="submit"
                />
              </FormDownloadWrapper>
            </>
          </AuthDisplayAuthorized>

          <AuthDisplayAuthorized level="MANAGER">
            <div className="block">
              <ModalButton
                icon={<IconTrashCan />}
                label={`Delete ${numberOfResults} ${inflect(
                  "work",
                  numberOfResults
                )}`}
                data-testid="button-batch-all-delete"
                onClick={handleDeleteAllItemsClick}
              />
            </div>
          </AuthDisplayAuthorized>
        </div>
      </SearchBatchModal>

      {/* Process selected items */}
      <SearchBatchModal
        handleCloseClick={() => setIsModalItemsOpen(false)}
        isOpen={isModalItemsOpen}
      >
        <div className="is-flex is-flex-direction-column is-align-items-center">
          <AuthDisplayAuthorized level="EDITOR">
            <div className="block">
              <ModalButton
                icon={<IconEdit />}
                label={`Batch edit ${numSelectedItems} ${inflect(
                  "work",
                  numSelectedItems
                )}`}
                data-testid="button-batch-items-edit"
                onClick={handleEditItemsClick}
              />
            </div>
            <div className="block">
              <ModalButton
                icon={<IconEdit />}
                label={`View and edit ${numSelectedItems} individual ${inflect(
                  "work",
                  numSelectedItems
                )}`}
                data-testid="button-view-and-edit"
                onClick={handleViewAndEditClick}
              />
            </div>
            <FormDownloadWrapper
              formAction="/api/export/selected_items.csv"
              queryValue={buildSelectedItemsQuery(selectedItems)}
            >
              <ModalButton
                icon={<IconCsv />}
                label={`Export metadata from ${numSelectedItems} ${inflect(
                  "work",
                  numSelectedItems
                )}`}
                data-testid="button-csv-items-export"
                type="submit"
              />
            </FormDownloadWrapper>

            <FormDownloadWrapper
              formAction="/api/create_shared_links/selected_items.csv"
              queryValue={buildSelectedItemsQuery(selectedItems)}
            >
              <ModalButton
                icon={<IconCsv />}
                label={`Download shared links for ${numSelectedItems} ${inflect(
                  "work",
                  numSelectedItems
                )}`}
                data-testid="button-csv-items-shared-links"
                type="submit"
              />
            </FormDownloadWrapper>
          </AuthDisplayAuthorized>
          <AuthDisplayAuthorized level="MANAGER">
            <div className="block">
              <ModalButton
                icon={<IconTrashCan />}
                label={`Delete ${numSelectedItems} ${inflect(
                  "work",
                  numSelectedItems
                )}`}
                data-testid="button-delete-items"
                onClick={handleDeleteItemsClick}
              />
            </div>
          </AuthDisplayAuthorized>
        </div>
      </SearchBatchModal>

      <BatchDeleteConfirmationModal
        numberOfResults={numberOfResults}
        filteredQuery={filteredQuery}
        handleCloseClick={() => setIsModalBatchDeleteConfirmationOpen(false)}
        isOpen={isModalBatchDeleteConfirmationOpen}
        selectedItems={selectedItems}
      />
    </>
  );
}

SearchActionRow.propTypes = {
  handleDeselectAll: PropTypes.func,
  handleEditAllItems: PropTypes.func.isRequired,
  handleEditItems: PropTypes.func.isRequired,
  handleViewAndEdit: PropTypes.func.isRequired,
  numberOfResults: PropTypes.number,
  selectedItems: PropTypes.array,
  filteredQuery: PropTypes.object,
};
