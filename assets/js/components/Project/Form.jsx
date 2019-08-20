import React from "react";
import { withRouter } from "react-router-dom";
import gql from "graphql-tag";
import { useMutation } from "@apollo/react-hooks";
import { toast } from "react-toastify";
import UIButton from "../UI/Button";
import UIButtonGroup from "../UI/ButtonGroup";
import { GET_PROJECTS } from "./List";

const ADD_PROJECT = gql`
  mutation CreateProject($projectTitle: String!) {
    createProject(title: $projectTitle) {
      id
      title
      folder
    }
  }
`;

const ProjectForm = ({ history }) => {
  let inputTitle;
  const [addProject, { data }] = useMutation(ADD_PROJECT, {
    onCompleted({ createProject }) {
      toast(`Project ${createProject.title} created successfully`, {
        type: "success"
      });
      history.push("/project/list");
    },
    refetchQueries(mutationResult) {
      return [{ query: GET_PROJECTS }];
    }
  });

  const handleCancel = e => {
    history.push("/project/list");
  };

  return (
    <>
      <form
        onSubmit={e => {
          e.preventDefault();
          addProject({
            variables: { projectTitle: inputTitle.value }
          });
        }}
      >
        <div className="mb-4">
          <label
            className="block text-gray-700 text-sm font-bold mb-2"
            htmlFor="username"
          >
            Project Title
          </label>
          <input
            id="project-title"
            type="text"
            placeholder="Project Title"
            ref={node => {
              inputTitle = node;
            }}
            className="text-input"
          />
        </div>

        <UIButtonGroup>
          <UIButton type="submit">Submit</UIButton>
          <UIButton classes="btn-cancel" onClick={handleCancel}>
            Cancel
          </UIButton>
        </UIButtonGroup>
      </form>
    </>
  );
};

export default withRouter(ProjectForm);
