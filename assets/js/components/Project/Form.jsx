import React, { useState } from "react";
import { useHistory, Link } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import UIButton from "../UI/Button";
import UIButtonGroup from "../UI/ButtonGroup";
import { CREATE_PROJECT, GET_PROJECTS } from "./project.query.js";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { useToasts } from "react-toast-notifications";

const ProjectForm = () => {
  const { addToast } = useToasts();
  let inputTitle;
  const history = useHistory();
  const [submitDisabled, setSubmitDisabled] = useState(true);
  const [formError, setFormError] = useState();
  let [createProject, { loading, error: mutationError, data }] = useMutation(
    CREATE_PROJECT,
    {
      onCompleted({ createProject }) {
        addToast(`Project ${createProject.title} created successfully`, {
          appearance: "success",
          autoDismiss: true
        });
        history.push("/project/list");
      },
      onError(error) {
        setFormError(error);
      },
      refetchQueries(mutationResult) {
        return [{ query: GET_PROJECTS }];
      }
    }
  );

  if (loading) return <Loading />;

  const handleCancel = () => {
    history.push("/project/list");
  };

  const handleInputChange = () => {
    setSubmitDisabled(inputTitle.value === "");
    if (formError) {
      setFormError(false);
    }
  };

  return (
    <div>
      {formError && (
        <div className="mb-8">
          <Error error={formError} />
        </div>
      )}
      <form
        onSubmit={e => {
          e.preventDefault();
          createProject({
            variables: { projectTitle: inputTitle.value }
          });
        }}
      >
        <div className="mb-4 md:w-1/2">
          <label
            className="block text-gray-700 text-sm font-bold mb-2"
            htmlFor="project-title"
          >
            Project Title
          </label>
          <input
            autoFocus
            id="project-title"
            data-testid="project-title-input"
            type="text"
            placeholder="Project Title"
            ref={node => {
              inputTitle = node;
            }}
            className="text-input"
            onChange={handleInputChange}
          />
        </div>

        <UIButtonGroup>
          <UIButton
            type="submit"
            disabled={submitDisabled || formError}
            data-testid="submit-button"
          >
            Submit
          </UIButton>
          <UIButton
            className="btn-clear"
            onClick={handleCancel}
            data-testid="cancel-button"
          >
            Cancel
          </UIButton>
        </UIButtonGroup>
      </form>
    </div>
  );
};

export default ProjectForm;
