import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";

const UISticky = ({ children, ...restProps }) => {
  const [headerHeight, setHeaderHeight] = useState();
  const styles = {
    headerStyle: {
      position: "-webkit-sticky",
      position: "sticky",
      top: headerHeight,
      zIndex: 100,
    },
  };

  useEffect(() => {
    const headerElement = document.getElementById("main-navigation")
      ? document.getElementById("main-navigation").getBoundingClientRect()
      : {};
    setHeaderHeight(headerElement.height);
  }, []);

  return (
    <div style={styles.headerStyle} {...restProps}>
      {children}
    </div>
  );
};

UISticky.propTypes = {
  children: PropTypes.node,
};

export default UISticky;
