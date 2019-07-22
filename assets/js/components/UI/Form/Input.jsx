import React from "react";
import PropTypes from "prop-types";

const UIInput = ({
  id = "",
  label = "An Input",
  name,
  type = "text",
  onChange
}) => (
  <div className="mb-4">
    <label htmlFor={name}>{label}</label>
    <input id={id} name={name} type={type} onChange={onChange} />
  </div>
);

UIInput.propTypes = {
  id: PropTypes.string,
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  type: PropTypes.string,
  onChange: PropTypes.func.isRequired
};

export default UIInput;
