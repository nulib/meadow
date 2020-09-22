import React from "react";
import PropTypes from "prop-types";
import { useFormContext } from "react-hook-form";

const UIFormInput = ({
  name,
  label,
  type = "text",
  required,
  ...passedInProps
}) => {
  const { errors, register } = useFormContext();

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
  type: PropTypes.oneOf(["date", "number", "text", "email", "hidden"]),
};

export default UIFormInput;
