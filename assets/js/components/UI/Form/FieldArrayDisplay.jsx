import React from "react";
import PropTypes from "prop-types";

const UIFormFieldArrayDisplay = ({ items = [], label = "" }) => {
  return (
    <div className="field content">
      <p data-testid="items-label">
        <strong>{label}</strong>
      </p>
      <ul data-testid="field-array-item-list">
        {items.map((item, i) => (
          <li key={i}>{item}</li>
        ))}
      </ul>
    </div>
  );
};

UIFormFieldArrayDisplay.propTypes = {
  items: PropTypes.array,
  label: PropTypes.string.isRequired,
};

export default UIFormFieldArrayDisplay;
