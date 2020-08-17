import React from "react";
import { Line as ProgressBar } from "rc-progress";
import PropTypes from "prop-types";

const UIProgressBar = ({ percentComplete, totalValue }) => {
  if (percentComplete < 100) {
    return (
      <>
        <div className="has-text-centered is-size-4">{`${Math.round(
          percentComplete
        )} % complete`}</div>
        <ProgressBar percent={percentComplete} strokeColor="#4e2a84" />
        <p className="has-text-centered">{`Ingesting ${
          totalValue || ""
        } file sets.`}</p>
      </>
    );
  }
  return null;
};

UIProgressBar.propTypes = {
  percentComplete: PropTypes.number,
  totalValue: PropTypes.number,
};

export default UIProgressBar;
