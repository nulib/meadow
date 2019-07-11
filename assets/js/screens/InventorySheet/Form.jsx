import React from "react";
import Main from "../../components/UI/Main";
import { withRouter } from "react-router-dom";
import InventorySheetForm from "../../components/InventorySheet/Form";

const ScreensInventorySheetForm = ({ history, match, location }) => {
  const { id } = match.params;

  const handleCancel = () => {
    history.push(`/project/${id}`);
  };

  const handleSubmit = e => {
    e.preventDefault();
  };

  return (
    <Main>
      <h1>Upload Inventory Sheet</h1>
      <InventorySheetForm
        handleCancel={handleCancel}
        handleSubmit={handleSubmit}
      />
    </Main>
  );
};

export default withRouter(ScreensInventorySheetForm);
