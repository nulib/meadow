import { ToastType, toast } from "bulma-toast";
import { URL_PATTERN_MATCH, URL_PATTERN_START } from "./global-vars";

import { FileSet } from "@js/__generated__/graphql";
import { Work } from "@nulib/dcapi-types";
import edtf from "edtf";
import moment from "moment";

type WorkWithESId<T> = Partial<T> & { _id: string };

/**
 * Escape double quotes (which may interfere with Search queries)
 * @param {string} str
 * @returns {string}
 */
export function escapeDoubleQuotes(str: string) {
  return str.replace(/["]+/g, '%5C"');
}

export function formatDate(date: string) {
  if (!date) return "";
  return moment.utc(date).local().format("lll");
}

export function formatSimpleISODate(date: string) {
  if (!date) return "";
  let newDate = moment(date).format().substring(0, 16);
  return newDate;
}

export function isUrlValid(url: string) {
  return Boolean(
    url.match(URL_PATTERN_MATCH) &&
      URL_PATTERN_START.some((validStart) => url.startsWith(validStart)),
  );
}

export function isEDTFValid(edtfString: string) {
  try {
    edtf(edtfString).edtf;
    return true;
  } catch (e) {
    return false;
  }
}

export function sortItemsArray(itemsArray = [], sortBy = "", order = "asc") {
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

export function getImageUrl(
  representativeImage:
    | string
    | {
        url: string;
        [key: string]: any;
      },
) {
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

export function prepWorkItemForDisplay(res: WorkWithESId<Work>) {
  return {
    id: res._id,
    collectionName: res.collection ? res.collection.title : "",
    title: res.title || "No title",
    updatedAt: res.modified_date,
    representativeImage: res.representative_file_set?.url || "",
    manifestUrl: res.iiif_manifest,
    published: res.published,
    visibility: res.visibility,
    fileSets: res.file_sets ? res.file_sets.length : 0,
    accessionNumber: res.accession_number,
    workTypeId: res.work_type?.toUpperCase(),
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

interface SortFileSetsProps {
  order?: "asc" | "desc";
  orderBy:
    | "accessionNumber"
    | "created"
    | "filename"
    | "id"
    | "role"
    | "verified";
  fileSets: FileSet[];
  verifiedFileSets: string[];
}

export function sortFileSets({
  order = "asc",
  orderBy = "created",
  fileSets = [],
  verifiedFileSets = [],
}: SortFileSetsProps): FileSet[] {
  if (!Array.isArray(fileSets) || fileSets.length === 0) {
    return [];
  }

  return [...fileSets].sort((a, b) => {
    let valA: string | number = "";
    let valB: string | number = "";

    switch (orderBy) {
      case "id":
        valA = a.id;
        valB = b.id;
        break;
      case "filename":
        valA = String(a?.coreMetadata?.originalFilename);
        valB = String(b?.coreMetadata?.originalFilename);
        break;
      case "role":
        valA = String(a.role.label);
        valB = String(b.role.label);
        break;
      case "accessionNumber":
        valA = a.accessionNumber;
        valB = b.accessionNumber;
        break;
      case "created":
        valA = new Date(a.insertedAt).getTime().toString();
        valB = new Date(b.insertedAt).getTime().toString();
        break;
      case "verified":
        valA = String(verifiedFileSets.includes(a.id));
        valB = String(verifiedFileSets.includes(b.id));
        break;
    }

    if (typeof valA === "number" && typeof valB === "number") {
      return order === "asc" ? valA - valB : valB - valA;
    }

    return order === "asc"
      ? valA.localeCompare(valB as string)
      : (valB as string).localeCompare(valA as string);
  });
}

export function toastWrapper(
  type: ToastType = "is-info",
  message = "Whoops, You forgot to include a message!",
) {
  return toast({
    message,
    type,
    dismissible: true,
    duration: 8000,
    position: "top-center",
    extraClasses: "meadow-toast-wrapper",
  });
}

export function s3Location(presignedUrl: string) {
  return `s3://${presignedUrl.split("?")[0].split("/").slice(-3).join("/")}`;
}

export function formatBytes(bytes: number, decimals: number) {
  if (bytes == 0) return "0 Bytes";
  var k = 1024,
    dm = decimals || 2,
    sizes = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"],
    i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + sizes[i];
}

export function getFileNameFromS3Uri(s3Uri: string) {
  const segments = s3Uri.split("/");
  return segments[segments.length - 1];
}
