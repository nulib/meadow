import React, { useEffect } from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import { useForm, FormProvider } from "react-hook-form";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormField from "@js/components/UI/Form/Field";

function DashboardsLocalAuthoritiesModalAdd({
  isOpen,
  handleAddLocalAuthority,
  handleClose,
}) {
  const methods = useForm();

  useEffect(() => {
    if (isOpen) methods.reset();
  }, [isOpen]);

  const onSubmit = (data) => {
    handleAddLocalAuthority(data);
    methods.reset();
    handleClose();
  };

  return (
    <FormProvider {...methods}>
      <form
        name="modal-mul-authority-add"
        data-testid="modal-nul-authority-add"
        className={`modal ${isOpen ? "is-active" : ""}`}
        onSubmit={methods.handleSubmit(onSubmit)}
        role="form"
      >
        <div className="modal-background"></div>
        <div className="modal-card">
          <header className="modal-card-head">
            <p className="modal-card-title">Add new NUL Authority Record</p>
            <button
              className="delete"
              aria-label="close"
              type="button"
              onClick={handleClose}
            ></button>
          </header>
          <section className="modal-card-body">
            <UIFormField label="Label" forId="label" required>
              <UIFormInput
                isReactHookForm
                required
                id="label"
                name="label"
                label="Label"
                placeholder="Add label here"
              />
            </UIFormField>
            <UIFormField label="Hint" forId="hint">
              <UIFormInput
                isReactHookForm
                id="hint"
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
            <Button isPrimary type="submit" data-testid="submit-button">
              Save changes
            </Button>
          </footer>
        </div>
      </form>
    </FormProvider>
  );
}

DashboardsLocalAuthoritiesModalAdd.propTypes = {
  handleAddLocalAuthority: PropTypes.func,
  isOpen: PropTypes.bool,
};

export default DashboardsLocalAuthoritiesModalAdd;
