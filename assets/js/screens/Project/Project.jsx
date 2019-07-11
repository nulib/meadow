import React, { useEffect, useState } from "react";
import Main from "../../components/UI/Main";
import { withRouter } from "react-router";
import axios from "axios";
import { toast } from "react-toastify";
import InventorySheetList from "../../components/InventorySheet/List";
import { Link } from "react-router-dom";

const Project = ({ match }) => {
  const { id } = match.params;
  const [project, setProject] = useState(null);

  useEffect(() => {
    const getProject = async () => {
      try {
        const response = await axios.get(`/api/v1/projects/${id}`);
        setProject(response.data.data);
      } catch (error) {
        toast(`Error fetching project: ${error}`);
      }
    };
    getProject();
  }, []);

  return (
    <Main>
      {project && (
        <div>
          <h1>{project.title}</h1>

          <h2>Inventory Sheets</h2>
          <Link
            to={{
              pathname: `/project/${id}/inventory-sheet/upload`,
              state: { projectId: project.id }
            }}
            className="btn mb-4"
          >
            Add Inventory Sheet
          </Link>
          <section className="content-block">
            <InventorySheetList projectId={project.id} />
          </section>
        </div>
      )}
    </Main>
  );
};

export default withRouter(Project);
