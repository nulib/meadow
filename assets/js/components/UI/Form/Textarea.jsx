import React from "react";
import PropTypes from "prop-types";
import { useFormContext } from "react-hook-form";

const UIFormTextarea = ({ name, label, required, ...passedInProps }) => {
  const { errors, register } = useFormContext();

  return (
    <>
      <textarea
        name={name}
        ref={register({ required })}
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
  name: PropTypes.string,
  label: PropTypes.string,
  required: PropTypes.bool,
};

export default UIFormTextarea;
