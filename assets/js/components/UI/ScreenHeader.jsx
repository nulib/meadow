import React from "react";
import PropTypes from "prop-types";
import BreadCrumbsNew from "./BreadcrumbsNew";

const ScreenHeader = ({ breadCrumbs, title = "", description = "" }) => {
  return (
    <div
      data-testid="screen-header"
      className="mb-2 px-6 max-w-3xl mx-auto lg:ml-0 lg:mr-auto xl:mx-0 xl:px-12 xl:w-3/4"
    >
      <h1 className="hidden">{title}</h1>
      <BreadCrumbsNew crumbs={breadCrumbs} />
      {description && (
        <p className="mt-0 mb-4 text-gray-600 font-thin">{description}</p>
      )}
      <hr className="my-8 border-b-2 border-gray-200" />
    </div>
  );
};

ScreenHeader.propTypes = {
  breadCrumbs: PropTypes.array,
  title: PropTypes.string.isRequired,
  description: PropTypes.string
};

export default ScreenHeader;
