import React from "react";
import PropTypes from "prop-types";

const UIInput = ({ ...props }) => {
  const { id, label } = props;

  return (
    <div className="field">
      {label && id && (
        <label className="label" htmlFor={id}>
          {props.label}
        </label>
      )}
      <div className="control">
        <input {...props} className="input" />
      </div>
    </div>
  );
};

UIInput.propTypes = {
  value: PropTypes.any
};

export default UIInput;
