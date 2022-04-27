import React from "react";
import PropTypes from "prop-types";

function NavDropdownItem({ children }) {
  return (
    <div role="menuitem" className={`navbar-item`}>
      {children}
    </div>
  );
}

NavDropdownItem.propTypes = {
  children: PropTypes.node,
};

export default NavDropdownItem;
