import React from "react";
import Main from "../../components/UI/Main";
import { withRouter } from "react-router-dom";
import InventorySheetForm from "../../components/InventorySheet/Form";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";

const ScreensInventorySheetForm = ({ match }) => {
  const { id } = match.params;

  return (
    <>
      <ScreenHeader title="New Ingest Job" description="Upload an Inventory sheet here to validate its contents and its work files exist in AWS" />
      <ScreenContent>
        {id && <InventorySheetForm projectId={id} yo="yo" />}
      </ScreenContent>

    </>
  );
};

export default withRouter(ScreensInventorySheetForm);
