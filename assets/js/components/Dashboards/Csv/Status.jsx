import React from "react";
import PropTypes from "prop-types";
function DashboardsCsvStatus({ status }) {
  let displayStatus = status.toUpperCase();
  let className = "is-success";
  if (displayStatus === "INVALID") {
    className = "is-danger";
  }
  return (
    <div data-testid="csv-job-status" className={`tag is-light ${className}`}>
      {displayStatus}
    </div>
  );
}

DashboardsCsvStatus.propTypes = {
  status: PropTypes.string,
};

export default DashboardsCsvStatus;
