import React, { useState } from "react";
import PropTypes from "prop-types";

const IngestSheetAlert = ({ ingestSheet }) => {
  const [showMessage, setShowMessage] = useState(true);
  if (!ingestSheet) return null;

  const { status, fileErrors } = ingestSheet;
  let alertObj = {};

  switch (status) {
    case "APPROVED":
      alertObj = {
        type: "is-info",
        title: "Approved",
        body:
          "The Ingest Sheet has been approved and the ingest is in progress.",
      };
      break;
    case "COMPLETED":
      alertObj = {
        type: "is-success",
        title: "Ingestion Complete",
        body: "All files have been processed.",
      };
      break;
    case "DELETED":
      // Not sure if someone could actually end up here
      alertObj = {
        type: "is-danger",
        title: "Deleted",
        body: "Ingest sheet no longer exists.",
      };
      break;
    case "FILE_FAIL":
      alertObj = {
        type: "is-danger",
        title: "File errors",
        body: fileErrors.length > 0 ? fileErrors.join(", ") : "",
      };
      break;
    case "ROW_FAIL":
      // Peel off ingestSheet.ingestSheetRows and inspect the "errors" array for each row to
      // give additional user feedback.  Put that data in "body"s value below.
      alertObj = {
        type: "is-danger",
        title: "File has failing rows",
        body: "See the error report below for details.",
      };
      break;
    case "UPLOADED":
      alertObj = {
        type: "is-info",
        title: "File uploaded",
        body: "Ingest sheet validation is in progress.",
      };
      break;
    case "VALID":
      alertObj = {
        type: "is-success",
        title: "File is valid",
        body: "All checks have passed and the ingest sheet is valid.",
      };
      break;
    default:
      break;
  }

  return showMessage ? (
    <article
      className={`notification is-light ${alertObj.type}`}
      data-testid="ui-alert"
    >
      <p>
        {alertObj.title}. {alertObj.body}
      </p>
    </article>
  ) : null;
};

IngestSheetAlert.propTypes = {
  ingestSheet: PropTypes.object,
};

export default IngestSheetAlert;
