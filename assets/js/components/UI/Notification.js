import React from "react";
import PropTypes from "prop-types";

const UINotification = ({ children, className, ...props }) => (
  <p {...props} className={`notification ${className}`}>
    <button className="delete"></button>
    {children}
  </p>
);

UINotification.propTypes = {
  children: PropTypes.node,
  className: PropTypes.oneOf([
    "is-primary",
    "is-link",
    "is-success",
    "is-danger",
    "is-warning",
    "is-info"
  ])
};

export default UINotification;
