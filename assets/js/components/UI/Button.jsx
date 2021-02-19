import React from "react";

// By default the UI button will appear as a "primary button" in color & style
const UIButton = ({ children, ...props }) => {
  const { disabled, className } = props;
  const classes = `button ${className ? className : ""}`;
  delete props.className;

  return (
    <button
      type="button"
      className={`${classes} ${disabled ? "btn-disabled" : ""} `}
      {...props}
    >
      {children}
    </button>
  );
};

export default UIButton;
