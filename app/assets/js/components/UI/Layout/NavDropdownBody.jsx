import React from "react";
import PropTypes from "prop-types";

function NavDropdownBody({ children, isExpanded }) {
  return (
    <div className="navbar-dropdown is-right" aria-expanded={isExpanded}>
      {children}
    </div>
  );
}

NavDropdownBody.propTypes = {
  children: PropTypes.node,
  isExpanded: PropTypes.bool,
};

export default NavDropdownBody;
