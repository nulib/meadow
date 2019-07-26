import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";

const Breadcrumbs = ({ crumbs }) => (
  <p className="breadcrumbs">
    {crumbs.map((crumb, i) => (
      <span key={crumb.label}>
        /{" "}
        {i !== crumbs.length - 1 && (
          <Link to={crumb.link} className="bg-gray-100 px-2">
            {crumb.label}
          </Link>
        )}
        {i === crumbs.length - 1 && <span className="px-2">{crumb.label}</span>}
      </span>
    ))}
  </p>
);

Breadcrumbs.propTypes = {
  crumbs: PropTypes.array.isRequired
};

export default Breadcrumbs;
