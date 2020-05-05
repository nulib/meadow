import React from "react";
import PropTypes from "prop-types";

const UIFormFieldAndDisplay = ({ label, children, childClass = "" }) => {
  return (
    <div className="field">
      <label className="label">{label}</label>
      <div className={`control ${childClass}`}>{children}</div>
    </div>
  );
};

UIFormFieldAndDisplay.propTypes = {
  label: PropTypes.string,
  children: PropTypes.node,
  childClass: PropTypes.string,
};

export default UIFormFieldAndDisplay;
