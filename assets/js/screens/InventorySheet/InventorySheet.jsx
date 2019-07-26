import React, { useEffect, useState } from "react";
import { withRouter } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import InventorySheetStatus from "../../components/InventorySheet/Status";
import Breadcrumbs from "../../components/UI/Breadcrumbs";
import { getProject } from "../../components/Project/Api";
import { getInventorySheet } from "../../components/InventorySheet/Api";
import ButtonGroup from "../../components/UI/ButtonGroup";
import UIButton from "../../components/UI/Button";

const ScreensInventorySheet = ({ match }) => {
  const { id, inventorySheetId } = match.params;

  const [project, setProject] = useState(null);
  const [inventorySheet, setInventorySheet] = useState(null);

  useEffect(() => {
    if (id) {
      const fn = async () => {
        const thisProject = await getProject(id);
        const thisInventorySheet = await getInventorySheet(
          id,
          inventorySheetId
        );

        setProject(thisProject);
        setInventorySheet(thisInventorySheet);
      };
      fn();
    }
  }, []);

  const createCrumbs = project => {
    if (!project || !inventorySheet) {
      return [];
    }
    return [
      {
        label: "Projects",
        link: "/project/list"
      },
      {
        label: `${project.title}`,
        link: `/project/${id}`
      },
      {
        label: `${inventorySheet.name}`,
        link: `/project/${id}/inventory-sheet/${inventorySheetId}`
      }
    ];
  };

  return (
    <>
      {project && (
        <ScreenHeader
          title="Inventory Sheet"
          description="The following is system validation/parsing of the .csv Inventory sheet.  Currently it checks 1.) Is it a .csv file?  2.) Are the appropriate headers present?  3.) Do files exist in AWS S3?"
          breadCrumbs={createCrumbs(project)}
        />
      )}
      <ScreenContent>
        <InventorySheetStatus inventorySheetId={inventorySheetId} />
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
