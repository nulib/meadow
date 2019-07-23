import React, { useEffect, useState } from "react";
import { withRouter } from "react-router";
import axios from "axios";
import { toast } from "react-toastify";
import InventorySheetList from "../../components/InventorySheet/List";
import { Link } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";

const Project = ({ match }) => {
  const { id } = match.params;
  const [project, setProject] = useState(null);

  useEffect(() => {
    const getProject = async () => {
      try {
        const response = await axios.get(`/api/v1/projects/${id}`);
        setProject(response.data.data);
      } catch (error) {
        toast(
          `Error fetching project: ${JSON.stringify(
            error.response.data.errors
          )}`
        );
      }
    };
    getProject();
  }, []);

  return (
    <>
      {project && (
        <>
          <ScreenHeader title={`Project: ${project.title}`} description="The following is a list of all active Ingest Jobs (or Inventory sheets) for a project" />

          <ScreenContent>

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
