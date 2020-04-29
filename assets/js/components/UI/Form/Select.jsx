import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";

const UIFormSelect = ({
  name,
  label,
  errors = {},
  register,
  required,
  options = [],
  defaultValue,
  ...passedInProps
}) => {
  return (
    <>
      <div className="select">
        <select
          name={name}
          ref={register({ required })}
          className={`input ${errors[name] ? "is-danger" : ""}`}
          defaultValue={defaultValue}
          {...passedInProps}
        >
          <option value="">-- Select --</option>
          {options.map((option) => (
            <option key={option.id || option.value} value={option.value}>
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
  errors: PropTypes.object.isRequired,
  register: PropTypes.func,
  required: PropTypes.bool,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string,
      label: PropTypes.string,
      value: PropTypes.string,
    })
  ),
};

export default UIFormSelect;
