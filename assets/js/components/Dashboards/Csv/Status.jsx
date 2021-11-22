import React from "react";
import PropTypes from "prop-types";
import { Tag } from "@nulib/design-system";
function DashboardsCsvStatus({ status }) {
  const displayStatus = status.toUpperCase();
  const isError = ["INVALID", "ERROR"].indexOf(displayStatus) > -1;
  const isPending = displayStatus === "PENDING";

  return (
    <Tag
      data-testid="csv-job-status"
      isDanger={isError}
      isSuccess={!isError}
      isWarning={isPending}
    >
      {displayStatus}
    </Tag>
  );
}

DashboardsCsvStatus.propTypes = {
  status: PropTypes.string,
};

export default DashboardsCsvStatus;
