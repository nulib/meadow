import React from "react";
import PropTypes from "prop-types";
import { IconAlert } from "@js/components/Icon";
import UIIconText from "@js/components/UI/IconText";

const IngestSheetAlert = ({ ingestSheet }) => {
  if (!ingestSheet) return null;

  const { status, fileErrors } = ingestSheet;
  let alertObj = {};

  switch (status) {
    case "APPROVED":
      alertObj = {
        type: "is-success",
        title: "",
        body: "The Ingest Sheet is valid and Works are being created.",
        icon: "check",
      };
      break;
    case "COMPLETED":
      alertObj = {
        type: "is-success",
        title: "Ingestion Complete",
        body: "Ingestion complete, and all Works have been created.",
        icon: "check-circle",
      };
      break;
    case "DELETED":
      // Not sure if someone could actually end up here
      alertObj = {
        type: "is-danger",
        title: "",
        body: "Ingest sheet no longer exists.",
        icon: "exclamation-triangle",
      };
      break;
    case "COMPLETED_ERROR":
      alertObj = {
        type: "is-danger",
        title: "Ingestion Complete (with errors)",
        body:
          "Ingestion complete, but some works and/or file sets have errors.",
        icon: "check-circle",
      };
      break;
    case "FILE_FAIL":
      alertObj = {
        type: "is-danger",
        title: "File errors",
        body: `File errors: ${
          fileErrors.length > 0 ? fileErrors.join(", ") : ""
        }`,
        icon: "exclamation-triangle",
      };
      break;
    case "ROW_FAIL":
      // Peel off ingestSheet.ingestSheetRows and inspect the "errors" array for each row to
      // give additional user feedback.  Put that data in "body"s value below.
      alertObj = {
        type: "is-danger",
        title: "File has failing rows",
        body: "File has failing rows. See the error report below for details.",
        icon: "exclamation-triangle",
      };
      break;
    case "UPLOADED":
      alertObj = {
        type: "is-warning",
        title: "File uploaded",
        body: "File uploaded and ingest sheet validation is in progress.",
        icon: "info-circle",
      };
      break;
    case "VALID":
      alertObj = {
        type: "is-success",
        title: "",
        body: "All checks have passed and the ingest sheet is valid.",
        icon: "thumbs-up",
      };
      break;
    default:
      break;
  }

  return (
    <article
      className={`notification ${
        alertObj.type !== "is-info" ? "is-light" : ""
      } ${alertObj.type}`}
      data-testid="ui-alert"
    >
      <UIIconText icon={<IconAlert />} isCentered>
        <p>{alertObj.body}</p>
      </UIIconText>
    </article>
  );
};

IngestSheetAlert.propTypes = {
  ingestSheet: PropTypes.object,
};

export default IngestSheetAlert;
