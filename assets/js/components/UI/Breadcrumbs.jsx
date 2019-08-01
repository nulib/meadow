import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";

const Breadcrumbs = ({ crumbs = [] }) => (
  <div className="text-xl mb-4">
    {crumbs.map((crumb, i) => (
      <span key={crumb.label}>
        <Link to={crumb.link}>{crumb.label}</Link>
        {i !== crumbs.length - 1 && <span className="px-4">></span>}
      </span>
    ))}
  </div>
);

Breadcrumbs.propTypes = {
  crumbs: PropTypes.array.isRequired
};

export default Breadcrumbs;
