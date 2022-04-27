import React from "react";
import PropTypes from "prop-types";

const UILevelItem = ({
  heading,
  content,
  contentClassname = "title",
  ...restProps
}) => (
  <div className="level-item has-text-centered" {...restProps}>
    <div>
      <p className="heading">{heading}</p>
      <p className={contentClassname}>{content}</p>
    </div>
  </div>
);

UILevelItem.propTypes = {
  heading: PropTypes.string.isRequired,
  content: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  contentClassname: PropTypes.string,
};

export default UILevelItem;
