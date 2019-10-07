import React from "react";
import UIAlert from "../UI/Alert";
import PropTypes from "prop-types";

const IngestSheetAlert = ({ ingestSheet }) => {
  if (!ingestSheet) return null;

  const { status, fileErrors } = ingestSheet;
  let alertObj = {};

  switch (status) {
    case "APPROVED":
      alertObj = {
        type: "info",
        title: "Approved",
        body: "The Ingest Sheet has been approved and the ingest is in progress"
      };
      break;
    case "COMPLETED":
      alertObj = {
        type: "success",
        title: "Ingestion Complete",
        body: "All files have been processed"
      };
      break;
    case "DELETED":
      // Not sure if someone could actually end up here
      alertObj = {
        type: "danger",
        title: "Deleted",
        body: "Ingest sheet no longer exists"
      };
      break;
    case "FILE_FAIL":
      alertObj = {
        type: "danger",
        title: "File errors",
        body: fileErrors.length > 0 ? fileErrors.map(error => `${error}`) : ""
      };
      break;
    case "ROW_FAIL":
      // Peel off ingestSheet.ingestSheetRows and inspect the "errors" array for each row to
      // give additional user feedback.  Put that data in "body"s value below.
      alertObj = {
        type: "danger",
        title: "File has failing rows",
        body: ""
      };
      break;
    case "UPLOADED":
      alertObj = {
        type: "info",
        title: "File uploaded",
        body: "Ingest sheet validation is in progress"
      };
      break;
    case "VALID":
      alertObj = {
        type: "success",
        title: "File is valid",
        body: "All checks have passed and the ingest sheet is valid."
      };
      break;
    default:
      break;
  }

  return <UIAlert {...alertObj} />;
};

IngestSheetAlert.propTypes = {
  ingestSheet: PropTypes.object
};

export default IngestSheetAlert;
