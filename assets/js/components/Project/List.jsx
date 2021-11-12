import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useMutation, useApolloClient } from "@apollo/client";
import { DELETE_PROJECT, GET_PROJECTS } from "./project.gql.js";
import UIModalDelete from "../UI/Modal/Delete";
import { formatDate, toastWrapper } from "@js/services/helpers";
import UIFormInput from "@js/components/UI/Form/Input";
import { Button } from "@nulib/design-system";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import ProjectForm from "@js/components/Project/Form";
import UISearchBarRow from "@js/components/UI/SearchBarRow";
import { IconEdit, IconTrashCan } from "@js/components/Icon";

const ProjectList = ({ projects }) => {
  const [modalOpen, setModalOpen] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [activeProject, setActiveProject] = useState();
  const [activeModal, setActiveModal] = useState();
  const [projectList, setProjectList] = useState();
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

  useEffect(() => {
    projects && projects.length > 0
      ? setProjectList(projects)
      : setProjectList([]);
  }, [projects]);

  const onOpenModal = (e, project) => {
    setActiveModal(project);
    setModalOpen(true);
  };

  const onEditProject = (project) => {
    setActiveProject(project);
    setShowForm(!showForm);
  };

  const onCloseModal = () => {
    setActiveModal(null);
    setModalOpen(false);
    setActiveProject(null);
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

  const handleFilterChange = (e) => {
    const filterValue = e.target.value.toUpperCase();

    if (!filterValue) {
      return setProjectList(projects);
    }
    const filteredList = projectList.filter((project) => {
      return project.title.toUpperCase().indexOf(filterValue) > -1;
    });
    setProjectList(filteredList);
  };

  return (
    <>
      <UISearchBarRow isCentered>
        <UIFormInput
          placeholder="Search projects"
          name="projectsSearch"
          label="Filter projects"
          onChange={handleFilterChange}
          data-testid="input-project-filter"
        />
      </UISearchBarRow>

      <div className="table-container">
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
              <AuthDisplayAuthorized>
                <th className="has-text-right">Actions</th>
              </AuthDisplayAuthorized>
            </tr>
          </thead>
          <tbody>
            {projectList &&
              projectList.map((project) => {
                const { id, folder, title, updatedAt, ingestSheets } = project;
                return (
                  <tr key={id}>
                    <td>
                      <Link
                        to={`/project/${id}`}
                        data-testid="project-title-row"
                      >
                        {title}
                      </Link>
                    </td>
                    <td>{folder}</td>
                    <td className="has-text-right">{ingestSheets.length}</td>
                    <td className="has-text-right">{formatDate(updatedAt)}</td>
                    <AuthDisplayAuthorized>
                      <td>
                        <div className="buttons-end">
                          <p className="control">
                            <Button
                              isLight
                              onClick={(e) => onEditProject(project)}
                            >
                              <IconEdit />
                            </Button>
                          </p>
                          <p className="control">
                            <Button
                              isLight
                              data-testid="delete-button-row"
                              onClick={(e) => onOpenModal(e, project)}
                            >
                              <IconTrashCan />
                            </Button>
                          </p>
                        </div>
                      </td>
                    </AuthDisplayAuthorized>
                  </tr>
                );
              })}
          </tbody>
        </table>
      </div>

      <ProjectForm
        showForm={showForm}
        setShowForm={setShowForm}
        project={activeProject}
        formType="edit"
      />
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
