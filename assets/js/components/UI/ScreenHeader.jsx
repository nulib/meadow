import React from "react";
import PropTypes from "prop-types";

const ScreenHeader = ({ title = "", description = "" }) => {
  return (
    <div data-testid="screen-header" className="">
      <h1 className="hidden">{title}</h1>
      {description && <p className="">{description}</p>}
      <hr className="" />
    </div>
  );
};

ScreenHeader.propTypes = {
  title: PropTypes.string.isRequired,
  description: PropTypes.string
};

export default ScreenHeader;
