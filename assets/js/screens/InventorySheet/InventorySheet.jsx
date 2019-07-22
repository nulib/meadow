import React from "react";
import Main from "../../components/UI/Main";
import { withRouter } from "react-router-dom";

const ScreensInventorySheet = ({ match }) => {
  const { id, inventorySheetId } = match.params;

  return (
    <>
      <h1>Inventory Sheet</h1>
      <section className="content-block">
        <p>Id: {inventorySheetId}</p>
        <img className="w-screen" src="/images/placeholder-content.png" />
      </section>
    </>
  );
};

export default withRouter(ScreensInventorySheet);
