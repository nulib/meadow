import React from "react";
import { Line as ProgressBar } from "rc-progress";
import PropTypes from "prop-types";

const UIProgressBar = ({ percentComplete, totalValue, isIngest = false }) => {
  if (percentComplete < 100) {
    return (
      <>
        <div className="has-text-centered mb-3">{`${Math.floor(
          percentComplete
        )} % complete`}</div>
        <ProgressBar percent={percentComplete} strokeColor="#4e2a84" />
        <p className="has-text-centered mt-3">
          {isIngest
            ? `Ingesting ${totalValue || ""} file sets.`
            : "Validating file sets"}
        </p>
      </>
    );
  }
  return null;
};

UIProgressBar.propTypes = {
  percentComplete: PropTypes.number,
  totalValue: PropTypes.number,
  isIngest: PropTypes.bool,
};

export default UIProgressBar;
