import React from "react";
import PropTypes from "prop-types";

const UILevelItem = ({ heading, content }) => (
  <div className="level-item has-text-centered">
    <div>
      <p className="heading">{heading}</p>
      <p className="title">{content}</p>
    </div>
  </div>
);

UILevelItem.propTypes = {
  heading: PropTypes.string.isRequired,
  content: PropTypes.string.isRequired,
};

export default UILevelItem;
