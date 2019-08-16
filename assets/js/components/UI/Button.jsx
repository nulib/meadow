import React from "react";
import PropTypes from "prop-types";

const UIButton = ({
  classes = "",
  disabled = false,
  onClick,
  type = "",
  children
}) => (
  <button
    className={`btn ${classes} ${disabled ? "btn-disabled" : ""}`}
    type={type}
    onClick={onClick}
    disabled={disabled}
  >
    {children}
  </button>
);

UIButton.propTypes = {
  children: PropTypes.node,
  classes: PropTypes.string,
  onClick: PropTypes.func,
  type: PropTypes.oneOf(["submit"])
};

export default UIButton;
