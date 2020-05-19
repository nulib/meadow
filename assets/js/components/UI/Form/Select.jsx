import React from "react";
import PropTypes from "prop-types";

const UIFormSelect = ({
  name,
  label,
  errors = {},
  register,
  required,
  options = [],
  defaultValue,
  showHelper,
  ...passedInProps
}) => {
  return (
    <>
      <div className="select">
        <select
          name={name}
          ref={register({ required })}
          className={`${errors[name] ? "is-danger" : ""}`}
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
      {errors[name] && (
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
