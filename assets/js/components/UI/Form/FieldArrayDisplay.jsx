import React from "react";
import PropTypes from "prop-types";

const UIFormFieldArrayDisplay = ({
  items = [],
  label = "",
  mocked,
  notLive,
}) => {
  return (
    <div className="field content mb-3">
      <p data-testid="items-label">
        <strong>{label}</strong> {mocked && <span className="tag">Mocked</span>}{" "}
        {notLive && <span className="tag">Not Live</span>}
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
  mocked: PropTypes.bool,
  notLive: PropTypes.bool,
};

export default UIFormFieldArrayDisplay;
