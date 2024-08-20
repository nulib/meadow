import { Button, Notification } from "@nulib/design-system";
import React, { useState } from "react";
import { useMutation, useQuery, useLazyQuery } from "@apollo/client";
import {
  DELETE_PROJECT,
  GET_PROJECTS,
  PROJECTS_SEARCH,
  UPDATE_PROJECT,
} from "./project.gql.js";
import { ModalDelete, SearchBarRow } from "@js/components/UI/UI";
import { formatDate, toastWrapper } from "@js/services/helpers";
import UIFormInput from "@js/components/UI/Form/Input";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import ProjectsModalEdit from "@js/components/Project/ModalEdit";
import { IconEdit, IconTrashCan } from "@js/components/Icon";
import { Link } from "react-router-dom";

const colHeaders = [
  "Project",
  "S3 Bucket Folder",
  "Ingest Sheets",
  "Last Updated",
  "Actions",
];

const ProjectList = () => {
  const [currentProject, setCurrentProject] = useState();
  const [filteredProjects, setFilteredProjects] = useState([]);
  const [searchValue, setSearchValue] = useState("");
  const [modalsState, setModalsState] = useState({
    delete: {
      isOpen: false,
    },
    update: {
      isOpen: false,
    },
  });

  const { loading, error, data } = useQuery(GET_PROJECTS, {
    pollInterval: 1000,
  });

  function filterValues() {
    if (!data) return;
    if (searchValue) {
      projectsSearch({
        variables: {
          query: searchValue,
        },
      });
    } else {
      setFilteredProjects([...data.projects]);
    }
  }

  const [
    deleteProject,
    { error: deleteProjectError, loading: deleteProjectLoading },
  ] = useMutation(DELETE_PROJECT, {
    update(cache, { data: { deleteProject } }) {
      cache.modify({
        fields: {
          projects(existingProjects = [], { readField }) {
            const newData = existingProjects.filter(
              (projectRef) => deleteProject.id !== readField("id", projectRef),
            );
            return [...newData];
          },
        },
      });
    },
    onError({ graphQLErrors, networkError }) {
      console.error("graphQLErrors", graphQLErrors);
      console.error("networkError", networkError);
      toastWrapper("is-danger", `Error deleting project.`);
    },
  });

  const [updateProject, { error: updateError, loading: updateLoading }] =
    useMutation(UPDATE_PROJECT, {
      onCompleted({ updateProject }) {
        toastWrapper("is-success", `Project: ${updateProject.title} updated`);
        setCurrentProject(null);
        filterValues();
      },
    });

  const [
    projectsSearch,
    {
      error: errorProjectsSearch,
      loading: loadingProjectsSearch,
      data: dataProjectsSearch,
    },
  ] = useLazyQuery(PROJECTS_SEARCH, {
    fetchPolicy: "network-only",
    onCompleted: (data) => {
      setFilteredProjects([...data.projectsSearch]);
    },
    onError({ graphQLErrors, networkError }) {
      console.error("graphQLErrors", graphQLErrors);
      console.error("networkError", networkError);
      toastWrapper("is-danger", `Error searching projects.`);
    },
  });

  React.useEffect(() => {
    if (!data) return;
    filterValues();
  }, [data, searchValue]);

  if (loading || deleteProjectLoading || updateLoading) return null;
  if (error) return <Notification isDanger>{error.toString()}</Notification>;
  if (deleteProjectError)
    return (
      <Notification isDanger>{deleteProjectError.toString()}</Notification>
    );
  if (updateError)
    return <Notification isDanger>{updateError.toString()}</Notification>;

  const handleConfirmDelete = () => {
    deleteProject({ variables: { projectId: currentProject.id } });
    setCurrentProject(null);
    setModalsState({ ...modalsState, delete: { isOpen: false } });
  };

  const handleDeleteClick = (project) => {
    setCurrentProject({ ...project });
    setModalsState({
      ...modalsState,
      delete: { isOpen: true },
    });
  };

  const handleUpdate = (formData) => {
    updateProject({
      variables: {
        projectTitle: formData.title,
        projectId: currentProject.id,
      },
    });
  };

  const handleUpdateButtonClick = (project) => {
    setCurrentProject({ ...project });
    setModalsState({
      ...modalsState,
      update: { isOpen: true },
    });
  };

  const handleSearchChange = (e) => {
    setSearchValue(e.target.value);
  };

  return (
    <React.Fragment>
      <SearchBarRow isCentered>
        <UIFormInput
          placeholder="Search"
          name="nulSearch"
          label="NUL search"
          onChange={handleSearchChange}
          value={searchValue}
        />
      </SearchBarRow>

      <div className="table-container">
        <table
          className="table is-striped is-fullwidth"
          data-testid="project-list"
        >
          <thead>
            <tr>
              {colHeaders.map((col) => (
                <th key={col}>{col}</th>
              ))}
            </tr>
          </thead>
          <tbody data-testid="projects-table-body">
            {filteredProjects.map((project) => {
              const { id, folder, title, updatedAt, ingestSheets } = project;

              return (
                <tr key={id} data-testid="projects-row">
                  <td>
                    <Link to={`/project/${id}`} data-testid="project-title-row">
                      {title}
                    </Link>
                  </td>
                  <td>{folder}</td>
                  <td>{ingestSheets.length}</td>
                  <td>{formatDate(updatedAt)}</td>
                  <td className="has-text-right is-right mb-0">
                    <div className="field is-grouped">
                      <AuthDisplayAuthorized>
                        <Button
                          isLight
                          data-testid="edit-button"
                          title="Edit Project"
                          className="is-small"
                          onClick={() => handleUpdateButtonClick(project)}
                        >
                          <IconEdit />
                        </Button>
                        <Button
                          isLight
                          data-testid="delete-button"
                          className="is-small"
                          onClick={() => handleDeleteClick(project)}
                        >
                          <IconTrashCan />
                        </Button>
                      </AuthDisplayAuthorized>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <ModalDelete
        isOpen={modalsState.delete.isOpen}
        handleClose={() =>
          setModalsState({
            ...modalsState,
            delete: {
              isOpen: false,
            },
          })
        }
        handleConfirm={handleConfirmDelete}
        thingToDeleteLabel={currentProject ? currentProject.title : ""}
      />

      <ProjectsModalEdit
        currentProject={currentProject}
        isOpen={modalsState.update.isOpen}
        handleClose={() =>
          setModalsState({
            ...modalsState,
            update: {
              isOpen: false,
            },
          })
        }
        handleUpdate={handleUpdate}
      />
    </React.Fragment>
  );
};

export default ProjectList;
