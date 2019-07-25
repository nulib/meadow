import React from "react";
import PropTypes from "prop-types";
import BreadCrumbs from "./Breadcrumbs";

const ScreenHeader = ({ breadCrumbs, title = "", description = "" }) => {
  return (
    <div className="mb-2 px-6 max-w-3xl mx-auto lg:ml-0 lg:mr-auto xl:mx-0 xl:px-12 xl:w-3/4">
      <h1>{title}</h1>
      {description && <p className="mt-0 mb-4 text-gray-600">{description}</p>}
      <hr className="mt-8 mb-1 border-b-2 border-gray-200" />
    </div>
  );
};

ScreenHeader.propTypes = {
  breadCrumbs: PropTypes.array,
  title: PropTypes.string.isRequired,
  description: PropTypes.string
};

export default ScreenHeader;
