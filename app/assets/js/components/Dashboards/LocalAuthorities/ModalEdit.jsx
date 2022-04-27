import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import { useForm, FormProvider } from "react-hook-form";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormField from "@js/components/UI/Form/Field";

function DashboardsLocalAuthoritiesModalEdit({
  currentAuthority,
  handleClose,
  handleUpdate,
  isOpen,
}) {
  if (!currentAuthority) return null;
  const [defaultValues, setDefaultValues] = React.useState({
    hint: "",
    label: "",
  });
  const methods = useForm();
  const { isDirty } = methods.formState;

  React.useEffect(() => {
    setDefaultValues({
      hint: currentAuthority.hint,
      label: currentAuthority.label,
    });
  }, [currentAuthority]);

  const onSubmit = (data) => {
    handleUpdate(data);
    methods.reset();
    handleClose();
  };

  return (
    <FormProvider {...methods}>
      <form
        name="modal-mul-authority-update"
        data-testid="modal-nul-authority-update"
        className={`modal ${isOpen ? "is-active" : ""}`}
        onSubmit={methods.handleSubmit(onSubmit)}
        role="form"
      >
        <div className="modal-background"></div>
        <div className="modal-card">
          <header className="modal-card-head">
            <p className="modal-card-title">Update NUL Authority Record</p>
            <button
              className="delete"
              aria-label="close"
              type="button"
              onClick={handleClose}
            ></button>
          </header>
          <section className="modal-card-body">
            <UIFormField
              label="Label"
              forId="nul-authority-edit-label"
              required
            >
              <UIFormInput
                defaultValue={defaultValues.label}
                isReactHookForm
                required
                id="nul-authority-edit-label"
                name="label"
                label="Label"
                placeholder="Add label here"
              />
            </UIFormField>
            <UIFormField label="Hint" forId="nul-authority-edit-hint">
              <UIFormInput
                defaultValue={defaultValues.hint}
                isReactHookForm
                id="nul-authority-edit-hint"
                name="hint"
                label="Hint"
                placeholder="Add hint here"
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

DashboardsLocalAuthoritiesModalEdit.propTypes = {
  currentAuthority: PropTypes.object,
  handleClose: PropTypes.func,
  handleUpdate: PropTypes.func,
  isOpen: PropTypes.bool,
};

export default DashboardsLocalAuthoritiesModalEdit;
