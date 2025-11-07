import React from "react";

/**
 * Simple text editor for string values
 */
const TextEditor = ({ value, onChange }) => {
  return (
    <input
      type="text"
      className="input"
      value={value || ""}
      onChange={(e) => onChange(e.target.value)}
    />
  );
};

export default TextEditor;
