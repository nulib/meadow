import React from "react";
import PropTypes from "prop-types";

const UICodedTermItem = ({ item = {} }) => {
  if (!item) return null;

  if (!item.id) return null;

  return <p>{item.label}</p>;
};

UICodedTermItem.propTypes = {
  item: PropTypes.shape({
    id: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired,
  }),
};

export default UICodedTermItem;
