import React from "react";

const ButtonGroup = ({ children, ...props }) => (
  <div className="buttons" {...props}>
    {children}
  </div>
);

export default ButtonGroup;
