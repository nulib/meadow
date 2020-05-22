import React from "react";
import PropTypes from "prop-types";

const UIFormSelect = ({
  name,
  label,
  // TODO: Clean up usages of UIFormSelect to use "hasErrors" instead of passing in "errors" object
  errors = {},
  hasErrors,
  register = () => {},
  required,
  options = [],
  defaultValue,
  showHelper,
  ...passedInProps
}) => {
  return (
    <>
      <div className={`select ${hasErrors || errors[name] ? "is-danger" : ""}`}>
        <select
          name={name}
          ref={register({ required })}
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
  name: PropTypes.string.isRequired,
  label: PropTypes.string,
  errors: PropTypes.object,
  hasErrors: PropTypes.bool,
  register: PropTypes.func,
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
