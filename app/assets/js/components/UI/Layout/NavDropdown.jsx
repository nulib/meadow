import React from "react";
import PropTypes from "prop-types";

function NavDropdown({ children, ...restProps }) {
  return (
    <div className="navbar-item has-dropdown is-hoverable" {...restProps}>
      {children}
    </div>
  );
}

NavDropdown.propTypes = {
  children: PropTypes.node.isRequired,
};

export default NavDropdown;
