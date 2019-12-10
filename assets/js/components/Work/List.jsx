import React from "react";
import PropTypes from "prop-types";
import Work from "./Work";

const WorkList = ({ works = [] }) => {
  if (works.length === 0) {
    return null;
  }
  return (
    <div data-testid="work-list">
      {works.map(work => (
        <div key={work.id} className="my-8">
          <Work work={work} />
        </div>
      ))}
    </div>
  );
};

WorkList.propTypes = {
  works: PropTypes.array
};

export default WorkList;
