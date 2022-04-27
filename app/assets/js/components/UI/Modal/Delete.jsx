import React from "react";
import PropTypes from "prop-types";

const UIModalDelete = ({
  isOpen,
  handleClose,
  handleConfirm,
  thingToDeleteLabel,
}) => {
  return (
    <div
      className={`modal ${isOpen ? "is-active" : ""}`}
      data-testid="delete-modal"
    >
      <div className="modal-background"></div>
      <div className="modal-content">
        <div className="box">
          <div className="field">
            <label className="label">Delete {thingToDeleteLabel} ?</label>
            <p className="text-gray-600">This action cannot be undone.</p>
          </div>
          <div className="buttons is-right">
            <button className="button is-text" onClick={handleClose}>
              Cancel
            </button>
            <button className="button is-danger" onClick={handleConfirm}>
              Delete
            </button>
          </div>
        </div>
      </div>
      <button
        className="modal-close is-large"
        type="button"
        aria-label="close"
        onClick={handleClose}
      ></button>
    </div>
  );
};

UIModalDelete.propTypes = {
  isOpen: PropTypes.bool,
  handleClose: PropTypes.func,
  handleConfirm: PropTypes.func,
  thingToDeleteLabel: PropTypes.string,
};

export default UIModalDelete;
