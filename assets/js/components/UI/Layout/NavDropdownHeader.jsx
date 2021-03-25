import React from "react";
import PropTypes from "prop-types";

function NavDropdownHeader({ children, label }) {
  return <label className="navbar-link">{children}</label>;
}

NavDropdownHeader.propTypes = {
  children: PropTypes.node,
  label: PropTypes.string,
};

export default NavDropdownHeader;
