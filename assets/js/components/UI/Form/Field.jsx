import React from "react";
import PropTypes from "prop-types";

const UIFormField = ({ label, children }) => {
  return (
    <div className="field">
      <label className="label">{label}</label>
      <div className="control">{children}</div>
    </div>
  );
};

UIFormField.propTypes = {
  label: PropTypes.string,
  children: PropTypes.node,
};

export default UIFormField;
