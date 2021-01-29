import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useQuery } from "@apollo/client";
import Error from "../UI/Error";
import { useMutation, useApolloClient } from "@apollo/client";
import { DELETE_PROJECT, GET_PROJECTS } from "./project.gql.js";
import UIModalDelete from "../UI/Modal/Delete";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { formatDate, toastWrapper } from "@js/services/helpers";
import UISkeleton from "../UI/Skeleton";
import UIFormInput from "@js/components/UI/Form/Input";
import { Button } from "@nulib/admin-react-components";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import ProjectForm from "@js/components/Project/Form";
import UISearchBarRow from "@js/components/UI/SearchBarRow";

const ProjectList = () => {
  const [modalOpen, setModalOpen] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [activeProject, setActiveProject] = useState();
  const [activeModal, setActiveModal] = useState();
  const [projectList, setProjectList] = useState();
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

  useEffect(() => {
    projectsData && projectsData.projects && projectsData.projects.length > 0
      ? setProjectList(projectsData.projects)
      : setProjectList([]);
  }, [projectsData]);

  if (loading) return <UISkeleton rows={20} />;
  if (error) return <Error error={error} />;

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
      return setProjectList(projectsData.projects);
    }
    const filteredList = projectList.filter((project) => {
      return project.title.toUpperCase().indexOf(filterValue) > -1;
    });
    setProjectList(filteredList);
  };

  return (
    <>
      <UISearchBarRow>
        <UIFormInput
          placeholder="Search projects"
          name="projectsSearch"
          label="Filter projects"
          onChange={handleFilterChange}
          data-testid="input-project-filter"
        />
      </UISearchBarRow>

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
            <AuthDisplayAuthorized action="edit">
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
                    <Link to={`/project/${id}`} data-testid="project-title-row">
                      {title}
                    </Link>
                  </td>
                  <td>{folder}</td>
                  <td className="has-text-right">{ingestSheets.length}</td>
                  <td className="has-text-right">{formatDate(updatedAt)}</td>
                  <AuthDisplayAuthorized action="edit">
                    <td>
                      <div className="buttons-end">
                        <p className="control">
                          <Button
                            className="button"
                            onClick={(e) => onEditProject(project)}
                          >
                            <FontAwesomeIcon icon="edit" />
                          </Button>
                        </p>
                        <p className="control">
                          <Button
                            className="button"
                            data-testid="delete-button-row"
                            onClick={(e) => onOpenModal(e, project)}
                          >
                            <FontAwesomeIcon icon="trash" />
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
