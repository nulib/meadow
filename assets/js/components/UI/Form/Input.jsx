import React from "react";
import PropTypes from "prop-types";

const UIInput = ({ ...props }) => {
  const { id, label } = props;

  return (
    <div className="mb-4 w-full">
      {label && id && <label htmlFor={id}>{props.label}</label>}
      <input {...props} className="text-input" />
    </div>
  );
};

UIInput.propTypes = {
  value: PropTypes.any
};

export default UIInput;
