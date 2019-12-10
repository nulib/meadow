import React from "react";
import PropTypes from "prop-types";
import Work from "./Work";

const WorkRow = ({ work }) => {
  return (
    <>
      <div data-testid="work-row" className="w-full flex py-4">
        <div className="w-1/4">
          <img src="/images/placeholder-content.png" />
        </div>
        <div className="w-3/4 pl-4">
          <Work work={work} />
        </div>
      </div>
    </>
  );
};

WorkRow.propTypes = {
  work: PropTypes.object
};

export default WorkRow;
