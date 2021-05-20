import React from "react";
import PropTypes from "prop-types";
import { useFormContext } from "react-hook-form";

const UIFormSelect = ({
  isReactHookForm,
  name,
  label,
  // TODO: Clean up usages of UIFormSelect to use "hasErrors" instead of passing in "errors" object
  hasErrors,
  required,
  options = [],
  defaultValue,
  showHelper,
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
      <div className={`select ${hasErrors || errors[name] ? "is-danger" : ""}`}>
        <select
          name={name}
          {...(register && register(name, { required }))}
          defaultValue={defaultValue}
          {...passedInProps}
        >
          {showHelper && <option value="">-- Select --</option>}
          {options.map((option) => (
            <option
              key={option.id || option.value}
              value={option.id || option.value}
            >
              {option.label}
            </option>
          ))}
        </select>
      </div>
      {(hasErrors || errors[name]) && (
        <p data-testid="select-errors" className="help is-danger">
          {label || name} field is required
        </p>
      )}
    </>
  );
};

UIFormSelect.propTypes = {
  isReactHookForm: PropTypes.bool,
  name: PropTypes.string.isRequired,
  label: PropTypes.string,
  hasErrors: PropTypes.bool,
  required: PropTypes.bool,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string,
      label: PropTypes.string.isRequired,
      value: PropTypes.string,
    })
  ),
  showHelper: PropTypes.bool,
};

export default UIFormSelect;
