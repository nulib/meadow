import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";

function SearchBatchModal({ children, handleCloseClick, isOpen }) {
  return (
    <div
      className={`modal ${isOpen ? "is-active" : ""}`}
      data-testid="select-all-modal"
    >
      <div className="modal-background"></div>
      <div className="modal-card">
        <header className="modal-card-head">
          <p className="modal-card-title">Bulk actions</p>
          <button
            className="delete"
            aria-label="close"
            onClick={handleCloseClick}
            data-testid="header-close-button"
          ></button>
        </header>
        <section className="modal-card-body">{children}</section>
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
  children: PropTypes.node,
  handleCloseClick: PropTypes.func.isRequired,
  isOpen: PropTypes.bool,
};

export default SearchBatchModal;
