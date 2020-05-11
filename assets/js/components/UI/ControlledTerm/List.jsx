import React from "react";
import PropTypes from "prop-types";

const UIControlledTermList = ({ items = [] }) => {
  if (!items) return;

  return (
    <ul data-testid="controlled-term-list">
      {items.map((item) => (
        <li key={item.id}>
          {item.label} {item.role && `(${item.role.label})`}
        </li>
      ))}
    </ul>
  );
};

UIControlledTermList.propTypes = {
  items: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string.isRequired,
      label: PropTypes.string.isRequired,
      role: PropTypes.obj,
    })
  ),
};

export default UIControlledTermList;
