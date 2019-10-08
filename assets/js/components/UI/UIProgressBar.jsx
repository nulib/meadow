import React from "react";
import { Line as ProgressBar } from "rc-progress";
import PropTypes from "prop-types";

const UIProgressBar = ({
  label,
  percentComplete,
  progressValue = percentComplete,
  isProgressValueAPercentage = true
}) => {
  if (percentComplete < 100) {
    return (
      <div className="my-4 pb-4">
        <div className="text-3xl font-light text-center pb-1 text-gray-600">
          {`${progressValue} ${isProgressValueAPercentage ? "%" : ""}`}
        </div>
        <ProgressBar percent={percentComplete} strokeColor="#2cb1bc" />
        <p className="text-gray-600 text-center mb-8 pt-2">...{label}</p>
      </div>
    );
  }
  return null;
};

UIProgressBar.propTypes = {
  label: PropTypes.string,
  percentComplete: PropTypes.number
};

export default UIProgressBar;
