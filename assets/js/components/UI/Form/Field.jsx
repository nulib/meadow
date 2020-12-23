import React from "react";
import PropTypes from "prop-types";

const UIFormField = ({
  label,
  children,
  childClass = "",
  forId,
  mocked,
  notLive,
  required,
  ...restProps
}) => {
  return (
    <div className="field" {...restProps}>
      <label className="label" htmlFor={forId || ""}>
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
  forId: PropTypes.string,
  mocked: PropTypes.bool,
  notLive: PropTypes.bool,
  required: PropTypes.bool,
  restProps: PropTypes.object,
};

export default UIFormField;
