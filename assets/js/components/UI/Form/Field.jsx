import React from "react";
import PropTypes from "prop-types";

const UIFormField = ({
  label,
  children,
  childClass = "",
  mocked,
  notLive,
  required,
}) => {
  return (
    <div className="field">
      <label className="label">
        {label} {required && <span>*</span>}{" "}
        {mocked && <span className="tag">Mocked</span>}{" "}
        {notLive && <span className="tag">Not Live</span>}
      </label>
      <div className={`control ${childClass}`}>{children}</div>
    </div>
  );
};

UIFormField.propTypes = {
  label: PropTypes.string,
  children: PropTypes.node,
  childClass: PropTypes.string,
  mocked: PropTypes.bool,
  notLive: PropTypes.bool,
  required: PropTypes.bool,
};

export default UIFormField;
