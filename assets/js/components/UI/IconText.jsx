import React from "react";
import PropTypes from "prop-types";
import classNames from "classnames";

function UIIconText({ children, icon, isCentered }) {
  return (
    <span
      className={classNames("is-flex", "is-align-items-center", {
        "is-justify-content-center": isCentered,
      })}
    >
      {icon}
      <span className="pl-3">{children}</span>
    </span>
  );
}

UIIconText.propTypes = {
  children: PropTypes.node,
  icon: PropTypes.node,
  isCentered: PropTypes.bool,
};

export default UIIconText;
