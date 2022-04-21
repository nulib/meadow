import React from "react";

const Loading = () => (
  <progress
    data-testid="loading"
    className="progress is-small is-primary"
    max="100"
  >
    15%
  </progress>
);

export default Loading;
