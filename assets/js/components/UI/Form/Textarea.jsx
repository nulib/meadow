import React from "react";
import PropTypes from "prop-types";
import { useFormContext } from "react-hook-form";

const UIFormTextarea = ({
  isReactHookForm,
  name,
  label,
  required,
  ...passedInProps
}) => {
  let errors = {},
    register;

  if (isReactHookForm) {
    const context = useFormContext();
    errors = context.formState.errors;
    register = context.register;
  }

  return (
    <>
      <textarea
        name={name}
        {...(register && register(name, { required }))}
        className={`textarea ${errors[name] ? "is-danger" : ""}`}
        {...passedInProps}
      />
      {errors[name] && (
        <p className="help is-danger">{label || name} field is required</p>
      )}
    </>
  );
};

UIFormTextarea.propTypes = {
  isReactHookForm: PropTypes.bool,
  name: PropTypes.string,
  label: PropTypes.string,
  required: PropTypes.bool,
};

export default UIFormTextarea;
