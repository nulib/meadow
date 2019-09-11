import React from "react";
import PropTypes from "prop-types";

const UIBadge = ({ label }) => (
  <span className="bg-teal-500 text-white text-xs px-2 rounded-full inline-block uppercase font-semibold tracking-wide">
    {label}
  </span>
);

UIBadge.propTypes = {
  label: PropTypes.string
};

export default UIBadge;
