import React from "react";
import { withRouter } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import ButtonGroup from "../../components/UI/ButtonGroup";
import UIButton from "../../components/UI/Button";

const ScreensInventorySheet = ({ match }) => {
  const { id, inventorySheetId } = match.params;

  const createCrumbs = () => {
    return [
      {
        label: "Projects",
        link: "/project/list"
      },
      {
        label: `(Project Title Goes Here)`,
        link: `/project/${id}`
      },
      {
        label: `(Inventory Sheet Title Goes Here)`,
        link: `/project/${id}/inventory-sheet/${inventorySheetId}`
      }
    ];
  };

  return (
    <>
      <ScreenHeader
        title="Inventory Sheet"
        description="The following is system validation/parsing of the .csv Inventory sheet.  Currently it checks 1.) Is it a .csv file?  2.) Are the appropriate headers present?  3.) Do files exist in AWS S3?"
        breadCrumbs={createCrumbs()}
      />
      <ScreenContent>
        <img className="w-screen" src="/images/placeholder-content.png" />
        <h3 className="italic pt-8">Coming Soon...</h3>
        <ButtonGroup>
          <UIButton label="Looks great, approve the sheet" />
          <UIButton classes="bg-red-500" label="Eject and start over" />
        </ButtonGroup>
      </ScreenContent>
    </>
  );
};

export default withRouter(ScreensInventorySheet);
