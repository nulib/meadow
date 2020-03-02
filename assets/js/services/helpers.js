import moment from "moment";
import { toast } from "bulma-toast";
import { IIIF_SIZES } from "./global-vars";

/**
 * Builds IIIF url for placeholder images
 * @param {string} id This ID is a filesetId
 * @param {object} imageSize This is an image size type
 * @return {string} This returns a URL for the image
 */
export function buildImageURL(id, imageSize) {
  const srcPath = id
    ? `http://localhost:8183/iiif/2/${id}`
    : "/images/1280x960.png";
  return srcPath + (id ? `${IIIF_SIZES[imageSize]}` : "");
}

/**
 * Escape double quotes (which may interfere with Search queries)
 * @param {string} str
 * @returns {string}
 */
export function escapeDoubleQuotes(str) {
  return str.replace(/["]+/g, '%5C"');
}

export function formatDate(date) {
  if (!date) return "";
  return moment.utc(date).format("lll");
}

export function formatSimpleISODate(date) {
  if (!date) return "";
  let newDate = moment(date)
    .format()
    .substring(0, 16);

  return newDate;
}

export function getClassFromIngestSheetStatus(status) {
  if (["ROW_FAIL", "FILE_FAIL"].indexOf(status) > -1) {
    return "is-danger";
  }
  if (status === "UPLOADED") {
    return "is-warning";
  }
  if (status === "COMPLETED") {
    return "is-success";
  }
  if (["APPROVED", "VALID"].indexOf(status) > -1) {
    return "is-success is-light";
  }
  return "";
}

export const TEMP_USER_FRIENDLY_STATUS = {
  UPLOADED: "Validation in progress...",
  ROW_FAIL: "Validation Errors",
  FILE_FAIL: "Validation Errors",
  VALID: "Valid, waiting for approval",
  APPROVED: "Ingest in progress...",
  COMPLETED: "Ingest Complete"
};

export function toastWrapper(
  type = "is-info",
  message = "Whoops, You forgot to include a message!"
) {
  return toast({
    message,
    type,
    dismissible: true,
    duration: 5000,
    position: "top-center"
  });
}
