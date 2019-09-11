import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import CheveronRightIcon from "../../../css/fonts/zondicons/cheveron-right.svg";

const Breadcrumbs = ({ crumbs = [] }) => (
  <div className="text-xl mb-4">
    {crumbs.map((crumb, i) => (
      <span key={crumb.label}>
        <Link to={crumb.link}>{crumb.label}</Link>
        {i !== crumbs.length - 1 && (
          <span className="px-4">
            <CheveronRightIcon className="icon" />
          </span>
        )}
      </span>
    ))}
  </div>
);

Breadcrumbs.propTypes = {
  crumbs: PropTypes.array.isRequired
};

export default Breadcrumbs;
