import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

function SearchBatchModal({
  handleCloseClick,
  handleCsvExport,
  handleEditAllItems,
  isOpen,
  numberOfResults,
}) {
  return (
    <div
      className={`modal ${isOpen ? "is-active" : ""}`}
      data-testid="select-all-modal"
    >
      <div className="modal-background"></div>
      <div className="modal-card">
        <header className="modal-card-head">
          <p className="modal-card-title">Batch update options</p>
          <button
            className="delete"
            aria-label="close"
            onClick={handleCloseClick}
          ></button>
        </header>
        <section className="modal-card-body">
          <div className="columns">
            <div className="column">
              <Button
                className="is-fullwidth"
                data-testid="button-batch-edit"
                onClick={handleEditAllItems}
              >
                <span className="icon">
                  <FontAwesomeIcon icon="edit" />
                </span>
                <span>Batch edit {numberOfResults} works</span>
              </Button>
            </div>
            <div className="column">
              <Button
                className="is-fullwidth"
                data-testid="button-csv-export"
                onClick={handleCsvExport}
              >
                <span className="icon">
                  <FontAwesomeIcon icon="file-csv" />
                </span>
                <span>Export metadata from {numberOfResults} works </span>
              </Button>
            </div>
          </div>
        </section>
        <footer className="modal-card-foot is-justify-content-flex-end">
          <Button isText onClick={handleCloseClick}>
            Cancel
          </Button>
        </footer>
      </div>
    </div>
  );
}

SearchBatchModal.propTypes = {
  handleCloseClick: PropTypes.func.isRequired,
  handleCsvExport: PropTypes.func.isRequired,
  handleEditAllItems: PropTypes.func.isRequired,
  isOpen: PropTypes.bool,
  numberOfResults: PropTypes.number.isRequired,
};

export default SearchBatchModal;
