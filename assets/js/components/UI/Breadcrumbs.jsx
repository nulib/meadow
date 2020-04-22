import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";

const Breadcrumbs = ({ items = [], ...props }) => (
  <nav
    className="breadcrumb has-succeeds-separator "
    aria-label="breadcrumbs"
    data-testid="breadcrumbs"
    {...props}
  >
    <ul>
      {items.map(({ label, route = "/", isActive }) =>
        isActive ? (
          <li key={label} className="is-active">
            <a aria-current="page">{label}</a>
          </li>
        ) : (
          <li key={label}>
            <Link to={route}>{label}</Link>
          </li>
        )
      )}
    </ul>
  </nav>
);

Breadcrumbs.propTypes = {
  items: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string.isRequred,
      route: PropTypes.string,
      isActive: PropTypes.bool,
    })
  ),
};

export default Breadcrumbs;
