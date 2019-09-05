import React from "react";
import { Line as ProgressBar } from "rc-progress";

const UIProgressBar = ({ percentComplete }) => {
  if (percentComplete < 100) {
    return (
      <div className="my-4 pb-4">
        <div className="text-3xl font-light text-center pb-1 text-gray-600">
          {percentComplete} %
        </div>
        <ProgressBar percent={percentComplete} strokeColor="#2cb1bc" />
        <p className="text-gray-600 text-center mb-8 pt-2">
          ...Please wait for validation
        </p>
      </div>
    );
  }
  return null;
};

export default UIProgressBar;
