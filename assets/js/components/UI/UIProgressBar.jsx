import React from "react";
import { Line as ProgressBar } from "rc-progress";
import PropTypes from "prop-types";

const UIProgressBar = ({ percentComplete, totalValue }) => {
  if (percentComplete < 100) {
    return (
      <div className="my-4 pb-4">
        <div className="text-3xl font-light text-center pb-1 text-gray-600">
          {`${Math.round(percentComplete)} % complete`}
        </div>
        <ProgressBar percent={percentComplete} strokeColor="#2cb1bc" />
        <p className="text-gray-600 text-center mb-8 pt-2">{`Ingesting ${totalValue} file sets.`}</p>
      </div>
    );
  }
  return null;
};

UIProgressBar.propTypes = {
  percentComplete: PropTypes.number,
  totalValue: PropTypes.number
};

export default UIProgressBar;
