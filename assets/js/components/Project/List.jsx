import React from "react";
import { Link } from "react-router-dom";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import DeleteIcon from "../../../css/fonts/zondicons/close.svg";
import { toast } from "react-toastify";
import { useMutation, useApolloClient } from "@apollo/react-hooks";
import { DELETE_PROJECT, GET_PROJECTS } from "./project.query.js";

const ProjectList = () => {
  const { loading, error, data: projectsData } = useQuery(GET_PROJECTS);
  const client = useApolloClient();
  const [deleteProject, { data }] = useMutation(DELETE_PROJECT, {
    update(
      cache,
      {
        data: { deleteProject }
      }
    ) {
      const { projects } = client.readQuery({ query: GET_PROJECTS });
      const index = projects.findIndex(
        project => project.id === deleteProject.id
      );
      projects.splice(index, 1);
      client.writeQuery({
        query: GET_PROJECTS,
        data: { projects }
      });
    }
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const handleDeleteClick = (e, project) => {
    if (project.ingestJobs.length > 0) {
      return toast(
        `Project has existing inventory jobs.  You must delete these before deleting project: ${project.title} `,
        { type: "error" }
      );
    }

    deleteProject({ variables: { projectId: project.id } });
  };

  return (
    <section className="my-6">
      <table>
        <thead>
          <tr>
            <th>Project</th>
            <th>s3 Bucket Folder</th>
            <th>Number of ingestion jobs</th>
            <th>Last Updated</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {projectsData.projects.length > 0 &&
            projectsData.projects.map(project => {
              const { id, folder, title, updated_at, ingestJobs } = project;
              return (
                <tr key={id}>
                  <td>
                    <Link to={`/project/${id}`}>{title}</Link>
                  </td>
                  <td>{folder}</td>
                  <td className="text-center">{ingestJobs.length}</td>
                  <td>{updated_at}</td>
                  <td>
                    <DeleteIcon
                      className="icon cursor-pointer"
                      onClick={e => handleDeleteClick(e, project)}
                    />
                  </td>
                </tr>
              );
            })}
        </tbody>
      </table>
    </section>
  );
};

export default ProjectList;
