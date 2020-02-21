import React, { useState } from "react";
import { useMutation } from "@apollo/react-hooks";
import { CREATE_PROJECT, GET_PROJECTS } from "./project.query.js";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { toastWrapper } from "../../services/helpers";

const ProjectForm = ({ showForm, setShowForm }) => {
  let inputTitle;
  const [submitDisabled, setSubmitDisabled] = useState(true);
  const [formError, setFormError] = useState();
  let [createProject, { loading, error: mutationError, data }] = useMutation(
    CREATE_PROJECT,
    {
      onCompleted({ createProject }) {
        toastWrapper(
          "is-success",
          `Project ${createProject.title} created successfully`
        );
        setShowForm(false);
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

  const handleSubmit = e => {
    e.preventDefault();
    createProject({
      variables: { projectTitle: inputTitle.value }
    });
  };

  const handleInputChange = () => {
    setSubmitDisabled(inputTitle.value === "");
    if (formError) {
      setFormError(false);
    }
  };

  return (
    <div>
      <div className={`modal ${showForm ? "is-active" : ""}`}>
        <form onSubmit={handleSubmit}>
          <div className="modal-background"></div>
          <div className="modal-content">
            <div className="box">
              {formError && (
                <div className="notification">
                  <Error error={formError} />
                </div>
              )}
              <div className="field">
                <label className="label" htmlFor="project-title">
                  Project
                </label>
                <div className="control">
                  <input
                    id="project-title"
                    type="text"
                    data-testid="project-title-input"
                    name="project-title"
                    className="input"
                    placeholder="Name your project..."
                    ref={node => {
                      inputTitle = node;
                    }}
                    onChange={handleInputChange}
                  />
                </div>
              </div>
              <div className="buttons is-right">
                <button
                  type="button"
                  className="button"
                  onClick={() => setShowForm(false)}
                  data-testid="cancel-button"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="button is-primary"
                  disabled={submitDisabled || formError}
                  data-testid="submit-button"
                >
                  Create
                </button>
              </div>
            </div>
          </div>
          <button
            className="modal-close is-large"
            type="button"
            aria-label="close"
            onClick={() => setShowForm(false)}
          ></button>
        </form>
      </div>
    </div>
  );
};

export default ProjectForm;
