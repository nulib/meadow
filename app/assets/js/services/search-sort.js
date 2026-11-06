/**
 * Sort options for the Search screen's result list: a sortable field plus a
 * direction, chosen with a select and a direction toggle button.
 *
 * Every sort is sent to OpenSearch with a secondary sort on the work id.
 * OpenSearch makes no promise about the order of tied documents between
 * requests, so without a unique tiebreaker a work can show up on two pages, or
 * on none, as the user scrolls through a large result set. Relevancy without a
 * search term is one giant tie, which is why the default sort used to shuffle.
 *
 * Works missing the sort field (for example undated works under a Date Created
 * sort) are placed last in both directions.
 */

// Browser localStorage key holding the user's last chosen sort
export const SEARCH_SORT_STORAGE_KEY = "meadowSearchSort";

export const SORT_DIRECTIONS = ["asc", "desc"];

const TIEBREAKER = { id: { order: "asc" } };

export const SEARCH_SORT_FIELDS = [
  {
    key: "relevancy",
    label: "Relevancy",
    directional: false,
    iconStyle: "amount",
    defaultDirection: "desc",
    directionLabels: {
      asc: "Least relevant first",
      desc: "Most relevant first",
    },
    sort: () => [{ _score: { order: "desc" } }],
  },
  {
    key: "date-created",
    label: "Date Created",
    directional: true,
    iconStyle: "amount",
    defaultDirection: "asc",
    directionLabels: { asc: "Oldest first", desc: "Newest first" },
    // A work's Date Created can be a span: oldest-first orders by where a span
    // starts, newest-first by where it ends.
    sort: (direction) =>
      direction === "asc"
        ? [{ date_created_start: { order: "asc", missing: "_last" } }]
        : [{ date_created_end: { order: "desc", missing: "_last" } }],
  },
  {
    key: "title",
    label: "Title",
    directional: true,
    iconStyle: "alpha",
    defaultDirection: "asc",
    directionLabels: { asc: "A to Z", desc: "Z to A" },
    sort: (direction) => [
      { "title.keyword": { order: direction, missing: "_last" } },
    ],
  },
  {
    key: "modified",
    label: "Modified Date",
    directional: true,
    iconStyle: "amount",
    defaultDirection: "desc",
    directionLabels: { asc: "Oldest first", desc: "Newest first" },
    sort: (direction) => [{ modified_date: { order: direction } }],
  },
  {
    key: "accession",
    label: "Accession Number",
    directional: true,
    iconStyle: "numeric",
    defaultDirection: "asc",
    directionLabels: { asc: "Ascending", desc: "Descending" },
    sort: (direction) => [{ accession_number: { order: direction } }],
  },
];

export const DEFAULT_SEARCH_SORT = { field: "relevancy", direction: "desc" };

/**
 * Look up a sort field by key, falling back to the default field
 * @param {string} key
 * @returns {Object} A sort field definition
 */
export function findSearchSortField(key) {
  return (
    SEARCH_SORT_FIELDS.find((field) => field.key === key) ||
    SEARCH_SORT_FIELDS.find((field) => field.key === DEFAULT_SEARCH_SORT.field)
  );
}

/**
 * Coerce anything into a valid { field, direction } sort
 * @param {Object} sort
 * @returns {Object} A valid sort
 */
export function normalizeSearchSort(sort) {
  const field = findSearchSortField(sort && sort.field);
  if (field.key !== (sort && sort.field)) return { ...DEFAULT_SEARCH_SORT };
  const direction = SORT_DIRECTIONS.includes(sort.direction)
    ? sort.direction
    : field.defaultDirection;
  return { field: field.key, direction };
}

/**
 * The sort to use when the user picks a field: that field's natural direction
 * @param {string} fieldKey
 * @returns {Object} A sort
 */
export function searchSortForField(fieldKey) {
  const field = findSearchSortField(fieldKey);
  return { field: field.key, direction: field.defaultDirection };
}

/**
 * Flip a sort's direction
 * @param {Object} sort
 * @returns {Object} A sort
 */
export function toggleSearchSortDirection(sort) {
  const current = normalizeSearchSort(sort);
  return {
    ...current,
    direction: current.direction === "asc" ? "desc" : "asc",
  };
}

/**
 * Build the OpenSearch `sort` clause for a sort, tiebreaker included
 * @param {Object} sort
 * @returns {Array} An OpenSearch sort array
 */
export function buildSearchSort(sort) {
  const { field, direction } = normalizeSearchSort(sort);
  return [...findSearchSortField(field).sort(direction), TIEBREAKER];
}

/**
 * The user's remembered sort, or the default when nothing valid is stored
 * @returns {Object} A sort
 */
export function readStoredSearchSort() {
  try {
    return normalizeSearchSort(
      JSON.parse(localStorage.getItem(SEARCH_SORT_STORAGE_KEY)),
    );
  } catch (e) {
    return { ...DEFAULT_SEARCH_SORT };
  }
}

/**
 * Remember a sort across page loads
 * @param {Object} sort
 */
export function storeSearchSort(sort) {
  try {
    localStorage.setItem(
      SEARCH_SORT_STORAGE_KEY,
      JSON.stringify(normalizeSearchSort(sort)),
    );
  } catch (e) {
    // Ignore storage failures (e.g. privacy mode); the in-memory state
    // still drives the current page.
  }
}
