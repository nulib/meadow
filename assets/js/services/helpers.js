import moment from "moment";
import { toast } from "bulma-toast";

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
  let newDate = moment(date).format().substring(0, 16);

  return newDate;
}

/**
 * Format a Controlled Term facet "key" value so it displays better in the UI
 * @param {String} key ie. "http://id.loc.gov/authorities/names/n50053919|mrb|Ranganathan, S. R. (Shiyali Ramamrita), 1892-1972 (Marbler)"
 */
export function formatControlledTermKey(key) {
  const arr = key.split("|");
  return arr.length === 0
    ? ""
    : `${arr[arr.length - 1]} - ${arr[0]} - ${arr[1]}`;
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
  COMPLETED: "Ingest Complete",
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
    position: "top-center",
  });
}

export function setVisibilityClass(visibility) {
  if (visibility.toUpperCase() === "RESTRICTED") {
    return "is-danger";
  }
  if (visibility.toUpperCase() === "AUTHENTICATED") {
    return "is-primary";
  }
  if (visibility.toUpperCase() === "OPEN") {
    return "is-success";
  }
  return "";
}
