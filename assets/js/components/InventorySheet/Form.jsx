import React from "react";
import ButtonGroup from "../../components/UI/ButtonGroup";
import PropTypes from "prop-types";

const InventorySheetForm = ({ handleSubmit, handleCancel, handleInputChange }) => {
  return (
    <form
      data-testid="inventory-sheet-upload-form"
      className="content-block"
      onSubmit={handleSubmit}
    >
      <div className="mb-4">
        <label htmlFor="ingest_job_name">Ingest Job Name</label>
        <input id="ingest_job_name" name="ingest_job_name" type="text" onChange={handleInputChange} />
      </div>
      <div className="mb-4">
        <label htmlFor="file">Inventory sheet file</label>
        <input id="file" name="file" type="file" onChange={handleInputChange} />
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
