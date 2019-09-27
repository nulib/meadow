import React from "react";
import { withRouter } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import { toast } from "react-toastify";
import UIButton from "../UI/Button";
import UIButtonGroup from "../UI/ButtonGroup";
import { CREATE_PROJECT, GET_PROJECTS } from "./project.query.js";
import Error from "../UI/Error";
import Loading from "../UI/Loading";

const ProjectForm = ({ history }) => {
  let inputTitle;
  const [createProject, { loading, error, data }] = useMutation(
    CREATE_PROJECT,
    {
      onCompleted({ createProject }) {
        toast(`Project ${createProject.title} created successfully`);
        history.push("/project/list");
      },
      refetchQueries(mutationResult) {
        return [{ query: GET_PROJECTS }];
      }
    }
  );

  if (error) return <Error error={error} />;
  if (loading) return <Loading />;

  const handleCancel = e => {
    history.push("/project/list");
  };

  return (
    <div className="md:w-1/2">
      <form
        onSubmit={e => {
          e.preventDefault();
          createProject({
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
          <UIButton classes="btn-clear" onClick={handleCancel}>
            Cancel
          </UIButton>
        </UIButtonGroup>
      </form>
    </div>
  );
};

export default withRouter(ProjectForm);
