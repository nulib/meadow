import moment from "moment";
import { toast } from "bulma-toast";
import { URL_PATTERN_MATCH, URL_PATTERN_START } from "./global-vars";
import edtf from "edtf";

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
  return moment.utc(date).local().format("lll");
}

export function formatSimpleISODate(date) {
  if (!date) return "";
  let newDate = moment(date).format().substring(0, 16);
  return newDate;
}

export function isUrlValid(url) {
  // console.log(url);
  // console.log(`url.match(URL_PATTERN_MATCH)`, url.match(URL_PATTERN_MATCH));
  return Boolean(
    url.match(URL_PATTERN_MATCH) &&
      URL_PATTERN_START.some((validStart) => url.startsWith(validStart))
  );
}

export function isEDTFValid(edtfString) {
  try {
    edtf(edtfString).edtf;
    return true;
  } catch (e) {
    return false;
  }
}

export function sortItemsArray(itemsArray = [], sortBy, order = "asc") {
  switch (order) {
    case "asc":
      return itemsArray
        .slice()
        .sort((a, b) => (a[sortBy] > b[sortBy] ? 1 : -1));
    case "desc":
      return itemsArray
        .slice()
        .sort((a, b) => (a[sortBy] > b[sortBy] ? -1 : 1));
    default:
      return itemsArray;
  }
}

export function getImageUrl(representativeImage) {
  if (representativeImage && typeof representativeImage === "object") {
    return representativeImage.url || "";
  }
  return representativeImage || "";
}

export const TEMP_USER_FRIENDLY_STATUS = {
  UPLOADED: "Validation in progress...",
  ROW_FAIL: "Validation Errors",
  FILE_FAIL: "Validation Errors",
  VALID: "Valid, waiting for approval",
  APPROVED: "Ingest in progress...",
  COMPLETED: "Ingest Complete",
  COMPLETED_ERROR: "Ingest Complete (with errors)",
};

export function prepWorkItemForDisplay(res) {
  return {
    id: res._id,
    collectionName: res.collection ? res.collection.title : "",
    title: res.descriptiveMetadata ? res.descriptiveMetadata.title : "No title",
    updatedAt: res.modifiedDate || res.updatedAt,
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

export function setVisibilityClass(visibility = "") {
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

/**
 * Helper function which orders an array of fileset objects by metadata.originalFilename
 * @param {Object} obj Object map of params
 * @param {String} obj.order Order preference: "asc" or "desc"
 * @param {Array} obj.fileSets file sets to order
 * @returns {Array}
 */
export function sortFileSets({ order = "asc", fileSets = [] }) {
  const orderedFileSets = [...fileSets].sort((a, b) => {
    const aName = a.coreMetadata.originalFilename;
    const bName = b.coreMetadata.originalFilename;

    if (aName === bName) return 0;

    switch (order) {
      case "asc":
        return aName < bName ? -1 : 1;
      case "desc":
        return aName < bName ? 1 : -1;
      default:
        break;
    }
  });

  return orderedFileSets;
}

export function toastWrapper(
  type = "is-info",
  message = "Whoops, You forgot to include a message!"
) {
  return toast({
    message,
    type,
    dismissible: true,
    duration: 8000,
    position: "top-center",
  });
}

export function s3Location(presignedUrl) {
  return `s3://${presignedUrl.split("?")[0].split("/").slice(-3).join("/")}`;
}

export function formatBytes(bytes, decimals) {
  if (bytes == 0) return "0 Bytes";
  var k = 1024,
    dm = decimals || 2,
    sizes = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"],
    i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + sizes[i];
}