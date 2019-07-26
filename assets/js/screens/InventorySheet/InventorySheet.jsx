import React from "react";
import Main from "../../components/UI/Main";
import { withRouter } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import InventorySheetStatus from "../../components/InventorySheet/Status";

const ScreensInventorySheet = ({ match }) => {
  const { id, inventorySheetId } = match.params;
  return (
    <>
      <ScreenHeader title="Inventory Sheet" description="The following is system validation/parsing of the .csv Inventory sheet, and some helpful user feedback" />
      <ScreenContent>
        <section>
          <h3>Id: {inventorySheetId}</h3>
          <InventorySheetStatus inventorySheetId={inventorySheetId}/>
        </section>
      </ScreenContent>

    </>
  );
};

export default withRouter(ScreensInventorySheet);
