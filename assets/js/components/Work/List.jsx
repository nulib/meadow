import React from "react";
import PropTypes from "prop-types";
import Work from "./Work";
import UICard from "../UI/Card";

const WorkList = ({ works = [] }) => {
  if (works.length === 0) {
    return null;
  }
  return (
    <div data-testid="work-list">
      {works.map(work => (
        <UICard key={work.id}>
          <Work work={work} />
        </UICard>
      ))}
    </div>
  );
};

WorkList.propTypes = {
  works: PropTypes.array
};

export default WorkList;
