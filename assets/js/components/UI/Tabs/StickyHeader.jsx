import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { ActionHeadline } from "@js/components/UI/UI";

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
    <div
      style={styles.headerStyle}
      className="box is-shadowless is-marginless has-background-light pt-3 pb-0"
      {...restProps}
    >
      <ActionHeadline>
        <h2 className="title is-size-4 has-text-grey">{title}</h2>
        <AuthDisplayAuthorized>
          <div className="buttons">{children}</div>
        </AuthDisplayAuthorized>
      </ActionHeadline>
    </div>
  );
};

UITabsStickyHeader.propTypes = {
  title: PropTypes.string,
  children: PropTypes.node,
};

export default UITabsStickyHeader;
