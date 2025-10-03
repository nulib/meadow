import React from "react";

const UIIndicator = ({ isActive = false }) => {
  return (
    <span
      data-status={isActive}
      style={{
        display: "inline-block",
        width: "0.625rem",
        height: "0.625rem",
        borderRadius: "50%",
        backgroundColor: isActive
          ? "var(--colors-green)"
          : "var(--colors-richBlack20)",
      }}
    ></span>
  );
};

export default UIIndicator;
