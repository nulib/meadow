import React from "react";
import { withRouter } from "react-router-dom";
import InventorySheetForm from "../../components/InventorySheet/Form";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";

const ScreensInventorySheetForm = ({ match }) => {
  const { id } = match.params;

  // TODO: Pull in Project via GraphQL here

  return (
    <>
      <ScreenHeader
        title="New Ingest Job"
        description="Upload an Inventory sheet here to validate its contents and its work files exist in AWS"
        breadCrumbs={[
          {
            label: "Projects",
            link: "/project/list"
          },
          {
            label: `(Project Title Goes Here)`,
            link: `/project/${id}`
          },
          {
            label: "Create ingest job",
            link: ""
          }
        ]}
      />

      <ScreenContent>
        {id && <InventorySheetForm projectId={id} />}
      </ScreenContent>
    </>
  );
};

export default withRouter(ScreensInventorySheetForm);
