import React from "react";
import ExclamationIcon from "../../../../css/fonts/zondicons/exclamation-solid.svg";
import Modal from "react-responsive-modal";
import PropTypes from "prop-types";

const UIModalDelete = ({
  isOpen,
  handleClose,
  handleConfirm,
  thingToDeleteLabel
}) => {
  return (
    <Modal center open={isOpen} onClose={handleClose}>
      <div className="flex">
        <ExclamationIcon className="icon w-16 h-16 text-danger-dark pr-4" />
        <div className="mr-8">
          <h4 className="uppercase text-sm font-bold leading-loose">
            Delete {thingToDeleteLabel}
          </h4>
          <p className="text-gray-600">This action cannot be undone</p>
          <div className="button-group mt-8 flex justify-end">
            <button className="btn btn-clear" onClick={handleClose}>
              Cancel
            </button>
            <button className="btn btn-danger" onClick={handleConfirm}>
              Delete
            </button>
          </div>
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
