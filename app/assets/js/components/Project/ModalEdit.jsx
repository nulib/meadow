import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import { useForm, FormProvider } from "react-hook-form";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormField from "@js/components/UI/Form/Field";

function ProjectsModalEdit({
  currentProject,
  handleClose,
  handleUpdate,
  isOpen,
}) {
  if (!currentProject) return null;
  const [defaultValues, setDefaultValues] = React.useState({
    title: "",
  });
  const methods = useForm();
  const { isDirty } = methods.formState;

  React.useEffect(() => {
    setDefaultValues({
      title: currentProject.title,
    });
  }, [currentProject]);

  const onSubmit = (data) => {
    handleUpdate(data);
    methods.reset();
    handleClose();
  };

  return (
    <FormProvider {...methods}>
      <form
        name="modal-project-update"
        data-testid="modal-project-update"
        className={`modal ${isOpen ? "is-active" : ""}`}
        onSubmit={methods.handleSubmit(onSubmit)}
        role="form"
      >
        <div className="modal-background"></div>
        <div className="modal-card">
          <header className="modal-card-head">
            <p className="modal-card-title">Update Project</p>
            <button
              className="delete"
              aria-label="close"
              type="button"
              onClick={handleClose}
            ></button>
          </header>
          <section className="modal-card-body">
            <UIFormField
              label="Title"
              forId="project-edit-title"
              required
            >
              <UIFormInput
                defaultValue={defaultValues.title}
                isReactHookForm
                required
                id="project-edit-title"
                name="title"
                label="Title"
                placeholder="Add title here"
              />
            </UIFormField>
          </section>
          <footer className="modal-card-foot buttons is-right">
            <Button isText onClick={handleClose} data-testid="cancel-button">
              Cancel
            </Button>
            <Button
              isPrimary
              type="submit"
              data-testid="submit-button"
              disabled={!isDirty}
            >
              Save changes
            </Button>
          </footer>
        </div>
      </form>
    </FormProvider>
  );
}

ProjectsModalEdit.propTypes = {
  currentProject: PropTypes.object,
  handleClose: PropTypes.func,
  handleUpdate: PropTypes.func,
  isOpen: PropTypes.bool,
};

export default ProjectsModalEdit;
