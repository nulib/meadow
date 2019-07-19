import React from "react";
import PropTypes from "prop-types";

const UIButton = ({
  classes = "",
  disabled = false,
  label = "Button Label",
  onClick,
  type = ""
}) => (
  <button
    className={`btn ${classes} ${disabled ? "btn-disabled" : ""}`}
    type={type}
    onClick={onClick}
    disabled={disabled}
  >
    {label}
  </button>
);

UIButton.propTypes = {
  classes: PropTypes.string,
  label: PropTypes.string.isRequired,
  onClick: PropTypes.func,
  type: PropTypes.oneOf(["submit"])
};

export default UIButton;
