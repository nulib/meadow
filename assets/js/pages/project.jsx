import React, { useEffect, useState } from "react";
import Main from "../components/Main";
import { withRouter } from "react-router";
import axios from "axios";
import { toast } from "react-toastify";

const ProjectPage = ({ match }) => {
  const { id } = match.params;
  const [project, setProject] = useState({});

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
          <section className="content-block">
            <p>
              <span className="font-bold">Id: </span>
              {project.id}
            </p>
            <p>
              <span className="font-bold">s3 Bucket Folder: </span>
              <a href="#">{project.folder}</a>
            </p>
          </section>
        </div>
      )}
    </Main>
  );
};

export default withRouter(ProjectPage);
