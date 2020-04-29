import React from "react";
import PropTypes from "prop-types";

const UIFormTextarea = ({
  name,
  label,
  errors = {},
  register,
  required,
  ...passedInProps
}) => {
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
  errors: PropTypes.object,
  register: PropTypes.func,
  required: PropTypes.bool,
};

export default UIFormTextarea;
