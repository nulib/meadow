import React from "react";
import PropTypes from "prop-types";

const WorkTabsHeader = ({ title, children }) => {
  return (
    <header>
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

WorkTabsHeader.propTypes = {
  title: PropTypes.string,
  children: PropTypes.node,
};

export default WorkTabsHeader;
