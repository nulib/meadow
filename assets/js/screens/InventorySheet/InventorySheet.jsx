import React from "react";
import Main from "../../components/UI/Main";
import { withRouter } from "react-router-dom";

const ScreensInventorySheet = ({ history, match, location }) => {
  const { id, inventorySheetId } = match.params;

  return (
    <Main>
      <h1>Inventory Sheet</h1>
      <section className="content-block">
        <p>Show inventory sheet stuff here</p>
      </section>
    </Main>
  );
};

export default withRouter(ScreensInventorySheet);
