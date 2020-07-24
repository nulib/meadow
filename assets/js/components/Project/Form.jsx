import React, { useState } from "react";
import { useMutation } from "@apollo/client";
import { CREATE_PROJECT, GET_PROJECTS } from "./project.gql.js";
import { useForm } from "react-hook-form";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { toastWrapper } from "../../services/helpers";
import UIFormInput from "../UI/Form/Input.jsx";
import UIFormField from "../UI/Form/Field.jsx";

const ProjectForm = ({ showForm, setShowForm }) => {
  const [formError, setFormError] = useState();
  const { register, handleSubmit, watch, errors } = useForm();
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
      },
    }
  );

  if (loading) return <Loading />;

  const onSubmit = (data) => {
    createProject({
      variables: { projectTitle: data.title },
    });
  };

  return (
    <div>
      <div className={`modal ${showForm ? "is-active" : ""}`}>
        <form onSubmit={handleSubmit(onSubmit)} data-testid="project-form">
          <div className="modal-background"></div>
          <div className="modal-content">
            <div className="box">
              {formError && (
                <div className="notification">
                  <Error error={formError} />
                </div>
              )}

              <UIFormField label="Project Title">
                <UIFormInput
                  register={register}
                  required
                  label="Project Title"
                  errors={errors}
                  data-testid="project-title-input"
                  name="title"
                  placeholder="Name your project..."
                />
              </UIFormField>

              <div className="buttons is-right">
                <button
                  type="button"
                  className="button is-text"
                  onClick={() => setShowForm(false)}
                  data-testid="cancel-button"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="button is-primary"
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
