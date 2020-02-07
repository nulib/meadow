import moment from "moment";

/**
 * Helper function to chop a string into a limited word count, from the start of the text
 * @param {String} str - The string to chop
 * @param {Number} chopLength How many words to restrict the sentence to
 */
export function chopString(str, chopLength) {
  if (!str) {
    return "";
  }
  const extraText = str.split(" ").length > chopLength ? "..." : "";
  let chopped = str
    .split(" ")
    .splice(0, chopLength)
    .join(" ");
  return `${chopped}${extraText}`;
}

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
 * Get a random integer between `min` and `max`.
 * @param {number} min - min number
 * @param {number} max - max number
 * @return {number} a random integer
 */
export function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1) + min);
}

/**
 * Escape double quotes (which may interfere with Search queries)
 * @param {string} str
 * @returns {string}
 */
export function escapeDoubleQuotes(str) {
  return str.replace(/["]+/g, '%5C"');
}

export function prepGlobalSearchInput(searchValue) {
  return {
    pathname: `/search`,
    search: `?q="${escapeDoubleQuotes(searchValue)
      .split(" ")
      .join("+")}"`
  };
}
