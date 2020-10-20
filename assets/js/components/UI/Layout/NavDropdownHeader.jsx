import React from "react";
import PropTypes from "prop-types";

function NavDropdownHeader({ children, label }) {
  const inputId = `dropdown-${label}`;
  const labelId = `dropdown1-${label}-label`;

  return (
    <>
      <input
        type="checkbox"
        id={inputId}
        aria-haspopup="true"
        aria-labelledby={labelId}
      />
      <label id={labelId} htmlFor={inputId} className="navbar-link">
        {children}
      </label>
    </>
  );
}

NavDropdownHeader.propTypes = {
  children: PropTypes.node,
  label: PropTypes.string,
};

export default NavDropdownHeader;
