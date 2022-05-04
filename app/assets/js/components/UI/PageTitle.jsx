import React from "react";
import PropTypes from "prop-types";

function UIPageTitle({ children, ...restProps }) {
  return (
    <h1 className="title is-size-2-mobile" {...restProps}>
      {children}
    </h1>
  );
}

UIPageTitle.propTypes = {
  children: PropTypes.node,
};

export default UIPageTitle;
