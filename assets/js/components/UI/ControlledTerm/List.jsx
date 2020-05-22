import React from "react";
import PropTypes from "prop-types";

const styles = {
  item: {
    marginBottom: "1rem",
  },
};

const UIControlledTermList = ({ items = [] }) => {
  if (!items) return;

  return (
    <div className="content" style={styles.item}>
      <ul data-testid="controlled-term-list">
        {items.map((item) => (
          <li key={item.id}>
            {item.label} {item.role && `(${item.role.label})`}
          </li>
        ))}
      </ul>
    </div>
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
