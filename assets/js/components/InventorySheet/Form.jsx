import React from "react";
import ButtonGroup from "../../components/UI/ButtonGroup";
import PropTypes from "prop-types";

const InventorySheetForm = ({ handleSubmit, handleCancel }) => {
  return (
    <form
      data-testid="inventory-sheet-upload-form"
      className="content-block"
      onSubmit={handleSubmit}
    >
      <div className="mb-4">
        <label htmlFor="inventory-sheet-file">Inventory sheet</label>
        <input id="inventory-sheet-file" type="file" />
      </div>
      <ButtonGroup>
        <button className="btn" type="submit">
          Submit
        </button>
        <button className="btn btn-cancel" onClick={handleCancel}>
          Cancel
        </button>
      </ButtonGroup>
    </form>
  );
};

InventorySheetForm.propTypes = {
  handleSubmit: PropTypes.func.isRequired,
  handleCancel: PropTypes.func.isRequired
};

export default InventorySheetForm;
