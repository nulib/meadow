import React from "react";
import PropTypes from "prop-types";
import { Tag } from "@nulib/design-system";

function IngestSheetStatusTag({ status, children }) {
  return (
    <Tag
      isDanger={
        ["ROW_FAIL", "FILE_FAIL", "COMPLETED_ERROR"].indexOf(status) > -1
      }
      isSuccess={["APPROVED", "COMPLETED", "VALID"].indexOf(status) > -1}
      isWarning={status === "UPLOADED"}
    >
      {children}
    </Tag>
  );
}

IngestSheetStatusTag.propTypes = {
  children: PropTypes.node,
  status: PropTypes.string,
};

export default IngestSheetStatusTag;
