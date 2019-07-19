import React from "react";
import Main from "../../components/UI/Main";
import { withRouter } from "react-router-dom";
import InventorySheetForm from "../../components/InventorySheet/Form";

const ScreensInventorySheetForm = ({ match }) => {
  const { id } = match.params;

  return (
    <Main>
      <h1>New Ingest Job</h1>
      {id && <InventorySheetForm projectId={id} yo="yo" />}
    </Main>
  );
};

export default withRouter(ScreensInventorySheetForm);
