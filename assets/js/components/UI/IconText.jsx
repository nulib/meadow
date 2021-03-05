import React from "react";
import PropTypes from "prop-types";
import classNames from "classnames";

function UIIconText({ icon, text, isCentered }) {
  return (
    <span
      className={classNames("is-flex", "is-align-items-center", {
        "is-justify-content-center": isCentered,
      })}
    >
      {icon}
      <span className="pl-3">{text}</span>
    </span>
  );
}

UIIconText.propTypes = {
  icon: PropTypes.node,
  text: PropTypes.string,
  isCentered: PropTypes.bool,
};

export default UIIconText;
