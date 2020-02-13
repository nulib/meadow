import moment from "moment";

export function formatDate(date) {
  if (!date) return "";
  return moment(date).format("MMM Do YYYY, h:mm:ss a");
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

/**
 * Escape double quotes (which may interfere with Search queries)
 * @param {string} str
 * @returns {string}
 */
export function escapeDoubleQuotes(str) {
  return str.replace(/["]+/g, '%5C"');
}
