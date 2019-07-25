import React, { useEffect, useState } from "react";
import { withRouter } from "react-router";
import InventorySheetList from "../../components/InventorySheet/List";
import { Link } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Breadcrumbs from "../../components/UI/Breadcrumbs";
import { getProject } from "../../components/Project/Api";

const Project = ({ match }) => {
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

  const createCrumbs = project => {
    if (!project) {
      return "";
    }
    return [
      {
        label: "Projects",
        link: "/project/list"
      },
      {
        label: `${project.title}`,
        link: `/project/${project.id}`
      }
    ];
  };

  return (
    <>
      {project && (
        <>
          <ScreenHeader
            title={project.title}
            description="The following is a list of all active Ingest Jobs (or Inventory sheets) for a project"
          />

          <ScreenContent>
            <Breadcrumbs crumbs={createCrumbs(project)} />
            <Link
              to={{
                pathname: `/project/${id}/inventory-sheet/upload`,
                state: { projectId: project.id }
              }}
              className="btn mb-4"
            >
              New Ingest Job
            </Link>
            <h2>Ingest Jobs</h2>
            <section>
              <InventorySheetList projectId={project.id} />
            </section>
          </ScreenContent>
        </>
      )}
    </>
  );
};

export default withRouter(Project);
