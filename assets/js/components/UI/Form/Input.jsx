import React from "react";
import PropTypes from "prop-types";

const UIFormInput = ({
  name,
  label,
  type = "text",
  errors = {},
  register,
  required,
  ...passedInProps
}) => {
  return (
    <>
      <input
        name={name}
        type={type}
        ref={register({ required })}
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
  name: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  type: PropTypes.oneOf(["date", "number", "text"]),
  errors: PropTypes.object.isRequired,
  register: PropTypes.func,
};

export default UIFormInput;
