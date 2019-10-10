import React, { useState } from "react";
import { Link } from "react-router-dom";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import TrashIcon from "../../../css/fonts/zondicons/trash.svg";
import { toast } from "react-toastify";
import { useMutation, useApolloClient } from "@apollo/react-hooks";
import { DELETE_PROJECT, GET_PROJECTS } from "./project.query.js";
import UIModalDelete from "../UI/Modal/Delete";

const ProjectList = () => {
  const [modalOpen, setModalOpen] = useState(false);
  const [activeModal, setActiveModal] = useState();
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
      toast(
        `Project has existing ingest sheets.  You must delete these before deleting project: ${activeModal.title} `,
        { type: "error" }
      );
      return setActiveModal(null);
    }

    deleteProject({ variables: { projectId: activeModal.id } });
    setActiveModal(null);
  };

  return (
    <>
      <section data-testid="project-list" className="my-6">
        <table>
          <caption>All Projects</caption>
          <thead>
            <tr>
              <th>Project</th>
              <th>s3 Bucket Folder</th>
              <th className="text-right">Number of ingestion sheets</th>
              <th>Last Updated</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {projectsData.projects &&
              projectsData.projects.length > 0 &&
              projectsData.projects.map(project => {
                const { id, folder, title, updatedAt, ingestSheets } = project;
                return (
                  <tr key={id}>
                    <td>
                      <Link to={`/project/${id}`}>{title}</Link>
                    </td>
                    <td>{folder}</td>
                    <td className="text-right">{ingestSheets.length}</td>
                    <td>{updatedAt}</td>
                    <td className="pl-8">
                      <button onClick={e => onOpenModal(e, project)}>
                        <TrashIcon className="icon cursor-pointer" />
                      </button>
                    </td>
                  </tr>
                );
              })}
          </tbody>
        </table>
      </section>
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
