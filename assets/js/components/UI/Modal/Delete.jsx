import React from "react";
import Modal from "react-responsive-modal";
import PropTypes from "prop-types";
import ButtonGroup from "../ButtonGroup";

const UIModalDelete = ({
  isOpen,
  handleClose,
  handleConfirm,
  thingToDeleteLabel
}) => {
  return (
    <Modal center open={isOpen} onClose={handleClose}>
      <div className="flex">
        <div className="mr-8">
          <h4 className="uppercase text-sm font-bold leading-loose">
            Delete {thingToDeleteLabel}
          </h4>
          <p className="text-gray-600">This action cannot be undone</p>
          <ButtonGroup>
            <button className="button" onClick={handleClose}>
              Cancel
            </button>
            <button className="button is-danger" onClick={handleConfirm}>
              Delete
            </button>
          </ButtonGroup>
        </div>
      </div>
    </Modal>
  );
};

UIModalDelete.propTypes = {
  isOpen: PropTypes.bool,
  handleClose: PropTypes.func,
  handleConfirm: PropTypes.func,
  thingToDeleteLabel: PropTypes.string
};

export default UIModalDelete;
