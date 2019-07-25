import React, { useEffect, useState } from "react";
import { withRouter } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import InventorySheetStatus from "../../components/InventorySheet/Status";
<<<<<<< HEAD
import { getProject } from "../../components/Project/Api";
import { getInventorySheet } from "../../components/InventorySheet/Api";
import ButtonGroup from "../../components/UI/ButtonGroup";
import UIButton from "../../components/UI/Button";
=======
import Breadcrumbs from "../../components/UI/Breadcrumbs";
import { getProject } from "../../components/Project/Api";
import { getInventorySheet } from "../../components/InventorySheet/Api";
>>>>>>> Add breadcrumbs, quickly, to the project to help in navigation for demo

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
        link: ""
      }
    ];
  };

  return (
    <>
      <ScreenHeader
        title="Inventory Sheet"
        description="The following is system validation/parsing of the .csv Inventory sheet, and some helpful user feedback"
      />
      <ScreenContent>
        {project && <Breadcrumbs crumbs={createCrumbs(project)} />}
        <p>Id: {inventorySheetId}</p>
        <InventorySheetStatus inventorySheetId={inventorySheetId} />
      </ScreenContent>
    </>
  );
};

export default withRouter(ScreensInventorySheet);
