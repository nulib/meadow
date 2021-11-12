import React, { useState } from "react";
import { useMutation } from "@apollo/client";
import { CREATE_PROJECT, GET_PROJECTS, UPDATE_PROJECT } from "./project.gql.js";
import { useForm, FormProvider } from "react-hook-form";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { toastWrapper } from "../../services/helpers";
import UIFormInput from "../UI/Form/Input.jsx";
import UIFormField from "../UI/Form/Field.jsx";
import { Button, Notification } from "@nulib/design-system";

const ProjectForm = ({ showForm, setShowForm, project = {}, formType }) => {
  const [formError, setFormError] = useState();
  const methods = useForm();
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

  let [updateProject] = useMutation(UPDATE_PROJECT, {
    onCompleted({ updateProject }) {
      toastWrapper(
        "is-success",
        `Project ${updateProject.title} updated successfully`
      );
      setShowForm(false);
    },
    onError(error) {
      setFormError(error);
    },
  });

  if (loading) return <Loading />;

  const onSubmit = (data) => {
    if (project.id) {
      updateProject({
        variables: { projectId: project.id, projectTitle: data.title },
      });
    } else {
      createProject({
        variables: { projectTitle: data.title },
      });
    }
  };

  return (
    <div>
      <div className={`modal ${showForm ? "is-active" : ""}`}>
        <FormProvider {...methods}>
          <form
            onSubmit={methods.handleSubmit(onSubmit)}
            data-testid="project-form"
          >
            <div className="modal-background"></div>
            <div className="modal-content">
              <div className="box">
                {formError && (
                  <Notification>
                    <Error error={formError} />
                  </Notification>
                )}

                <UIFormField label="Project Title">
                  <UIFormInput
                    id={`${formType}${project.id}`}
                    isReactHookForm
                    required
                    label="Project Title"
                    data-testid="project-title-input"
                    name="title"
                    placeholder="Name your project..."
                    defaultValue={project.title}
                    key={project.id}
                  />
                </UIFormField>

                <div className="buttons is-right">
                  <Button
                    isText
                    type="button"
                    onClick={() => setShowForm(false)}
                    data-testid="cancel-button"
                  >
                    Cancel
                  </Button>
                  <Button isPrimary type="submit" data-testid="submit-button">
                    {project && project.id ? "Update" : "Create"}
                  </Button>
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
        </FormProvider>
      </div>
    </div>
  );
};

export default ProjectForm;
