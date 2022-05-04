import React from "react";
import PropTypes from "prop-types";

function UIActionHeadline({ children, ...restProps }) {
  return (
    <header
      className="action-headline is-flex-desktop is-justify-content-space-between is-align-items-flex-start block"
      {...restProps}
    >
      {children}
    </header>
  );
}

UIActionHeadline.propTypes = {
  children: PropTypes.node,
};

export default UIActionHeadline;
