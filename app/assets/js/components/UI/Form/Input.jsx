import React from "react";
import PropTypes from "prop-types";
import { useFormContext } from "react-hook-form";

const UIFormInput = ({
  id = "",
  isReactHookForm,
  label = "",
  name,
  required,
  type = "text",
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
      <input
        id={id || name}
        name={name}
        type={type}
        {...(register && register(name, { required }))}
        className={`input ${errors[name] ? "is-danger" : ""}`}
        {...passedInProps}
      />
      {errors[name] && (
        <p data-testid="input-errors" className="help is-danger">
          {label || name} field is required
        </p>
      )}
    </>
  );
};

UIFormInput.propTypes = {
  id: PropTypes.string,
  isReactHookForm: PropTypes.bool,
  name: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  type: PropTypes.oneOf(["date", "number", "text", "email", "hidden"]),
};

export default UIFormInput;
