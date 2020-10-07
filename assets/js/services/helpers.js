import moment from "moment";
import { toast } from "bulma-toast";
import { URL_PATTERN_MATCH } from "./global-vars";

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

export function isUrlValid(url) {
  return url.match(URL_PATTERN_MATCH) ? true : false;
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

export function getImageUrl(representativeImage) {
  if (typeof representativeImage === "object") {
    return representativeImage.url || "";
  }
  return representativeImage;
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

export function prepWorkItemForDisplay(res) {
  return {
    id: res._id,
    collectionName: res.collection ? res.collection.title : "",
    title: res.descriptiveMetadata.title,
    updatedAt: res.modified_date || res.updatedAt,
    representativeImage:
      res.representativeFileSet ||
      (res.representativeImage ? res.representativeImage : ""),
    manifestUrl: res.iiifManifest,
    published: res.published,
    visibility: res.visibility,
    fileSets: res.fileSets ? res.fileSets.length : 0,
    accessionNumber: res.accessionNumber,
    workType: res.workType,
  };
}
