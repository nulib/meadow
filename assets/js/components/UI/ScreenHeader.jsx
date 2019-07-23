import React from "react";
import PropTypes from "prop-types";

const ScreenHeader = ({ title, description = "" }) => {
  return (
    <div className="mb-6 px-6 max-w-3xl mx-auto lg:ml-0 lg:mr-auto xl:mx-0 xl:px-12 xl:w-3/4">
      <h1>{title}</h1>
      {description && <p className="mt-0 mb-4 text-gray-600">{description}</p>}
      <hr className="my-8 border-b-2 border-gray-200" />
    </div>
  );
};

ScreenHeader.propTypes = {
  title: PropTypes.string.isRequired,
  description: PropTypes.string
};

export default ScreenHeader;
