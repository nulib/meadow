import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";

const UITabsStickyHeader = ({ title, children, ...restProps }) => {
  const [headerHeight, setHeaderHeight] = useState();
  const styles = {
    headerStyle: {
      position: "-webkit-sticky",
      position: "sticky",
      top: headerHeight,
      zIndex: 10,
    },
  };

  useEffect(() => {
    const headerElement = document.getElementById("main-navigation")
      ? document.getElementById("main-navigation").getBoundingClientRect()
      : {};
    setHeaderHeight(headerElement.height);
  }, []);

  return (
    <header
      style={styles.headerStyle}
      className="box is-shadowless is-marginless has-background-light py-0 px-4"
      {...restProps}
    >
      <div className="columns is-mobile">
        <div className="column is-half">
          <h2 className="title is-size-4 has-text-grey">{title}</h2>
        </div>
        <div className="column is-half ">
          <div className="buttons is-right">{children}</div>
        </div>
      </div>
    </header>
  );
};

UITabsStickyHeader.propTypes = {
  title: PropTypes.string,
  children: PropTypes.node,
};

export default UITabsStickyHeader;
