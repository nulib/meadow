import React, { useState } from "react";
import { Link } from "react-router-dom";
import { useQuery } from "@apollo/client";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { useMutation, useApolloClient } from "@apollo/client";
import { DELETE_PROJECT, GET_PROJECTS } from "./project.gql.js";
import UIModalDelete from "../UI/Modal/Delete";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { formatDate, toastWrapper } from "../../services/helpers";
import UISkeleton from "../UI/Skeleton";

const ProjectList = () => {
  const [modalOpen, setModalOpen] = useState(false);
  const [activeModal, setActiveModal] = useState();
  const { loading, error, data: projectsData } = useQuery(GET_PROJECTS);
  const client = useApolloClient();
  const [deleteProject, { data }] = useMutation(DELETE_PROJECT, {
    update(cache, { data: { deleteProject } }) {
      const { projects } = client.readQuery({ query: GET_PROJECTS });
      const index = projects.findIndex(
        (project) => project.id === deleteProject.id
      );
      projects.splice(index, 1);
      client.writeQuery({
        query: GET_PROJECTS,
        data: { projects },
      });
      toastWrapper("is-success", `Project deleted successfully`);
    },
  });

  if (loading) return <UISkeleton rows={20} />;
  if (error) return <Error error={error} />;

  const onOpenModal = (e, project) => {
    setActiveModal(project);
    setModalOpen(true);
  };

  const onCloseModal = () => {
    setActiveModal(null);
    setModalOpen(false);
  };

  const handleDeleteClick = () => {
    setModalOpen(false);
    if (activeModal.ingestSheets.length > 0) {
      toastWrapper(
        "is-danger",
        `Project has existing ingest sheets.  You must delete these before deleting project: ${activeModal.title} `
      );
      return setActiveModal(null);
    }
    deleteProject({ variables: { projectId: activeModal.id } });
    setActiveModal(null);
  };

  return (
    <>
      <table
        data-testid="project-list"
        className="table is-striped is-hoverable is-fullwidth"
      >
        <caption>All Projects</caption>
        <thead>
          <tr>
            <th>Project</th>
            <th>s3 Bucket Folder</th>
            <th className="text-right has-text-right"># Ingest Sheets</th>
            <th className="has-text-right">Last Updated</th>
            <th className="has-text-right">Actions</th>
          </tr>
        </thead>
        <tbody>
          {projectsData.projects &&
            projectsData.projects.length > 0 &&
            projectsData.projects.map((project) => {
              const { id, folder, title, updatedAt, ingestSheets } = project;
              return (
                <tr key={id}>
                  <td>
                    <Link to={`/project/${id}`}>{title}</Link>
                  </td>
                  <td>{folder}</td>
                  <td className="has-text-right">{ingestSheets.length}</td>
                  <td className="has-text-right">{formatDate(updatedAt)}</td>
                  <td>
                    <div className="buttons-end">
                      <p className="control">
                        <button className="button">
                          <FontAwesomeIcon icon="edit" />
                        </button>
                      </p>
                      <p className="control">
                        <button
                          className="button"
                          data-testid="delete-button"
                          onClick={(e) => onOpenModal(e, project)}
                        >
                          <FontAwesomeIcon icon="trash" />
                        </button>
                      </p>
                    </div>
                  </td>
                </tr>
              );
            })}
        </tbody>
      </table>
      <UIModalDelete
        isOpen={modalOpen}
        handleClose={onCloseModal}
        handleConfirm={handleDeleteClick}
        thingToDeleteLabel={`Project ${activeModal ? activeModal.title : ""}`}
      />
    </>
  );
};

export default ProjectList;
