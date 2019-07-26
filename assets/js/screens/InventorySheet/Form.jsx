import React, { useEffect, useState } from "react";
import { withRouter } from "react-router-dom";
import InventorySheetForm from "../../components/InventorySheet/Form";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import { getProject } from "../../components/Project/Api";

const ScreensInventorySheetForm = ({ match }) => {
  const { id } = match.params;
  const [project, setProject] = useState(null);

  useEffect(() => {
    if (id) {
      const fn = async () => {
        const thisProject = await getProject(id);
        setProject(thisProject);
      };
      fn();
    }
  }, []);

  return (
    <>
      {project && (
        <ScreenHeader
          title="New Ingest Job"
          description="Upload an Inventory sheet here to validate its contents and its work files exist in AWS"
          breadCrumbs={[
            {
              label: "Projects",
              link: "/project/list"
            },
            {
              label: `${project.title}`,
              link: `/project/${id}`
            },
            {
              label: "Create ingest job",
              link: ""
            }
          ]}
        />
      )}

      <ScreenContent>
        {id && <InventorySheetForm projectId={id} />}
      </ScreenContent>
    </>
  );
};

export default withRouter(ScreensInventorySheetForm);
