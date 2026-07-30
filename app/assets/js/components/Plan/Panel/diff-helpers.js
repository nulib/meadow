import {
  WORK_FIELDS,
  CONTROLLED_TERM_FIELDS,
  CODED_TERM_FIELDS,
  NESTED_CODED_TERM_FIELDS,
  TEXT_SINGLE_FIELDS,
  TEXT_ARRAY_FIELDS,
} from "@js/components/Plan/fields";
import { CONTROLLED_METADATA } from "@js/services/metadata";
import { provenanceItemId } from "@js/components/AIProvenance/Badges";

// ---------- path utilities ----------

/**
 * Convert one snake_case segment to camelCase
 */
const snakeToCamel = (s) => s.replace(/_([a-z])/g, (_, c) => c.toUpperCase());

/**
 * Convert a dotted snake_case path to a dotted camelCase path so it can be
 * walked into a GraphQL work object.
 * e.g. "descriptive_metadata.related_url" → "descriptiveMetadata.relatedUrl"
 */
const snakeToCamelPath = (path) => path.split(".").map(snakeToCamel).join(".");

/**
 * Look up the current (pre-change) value for a field path inside a work object.
 * Returns undefined when the work is missing or the path does not exist.
 */
const getCurrentValue = (path, work) => {
  if (!work) return undefined;
  const camelPath = snakeToCamelPath(path);
  return camelPath.split(".").reduce((obj, key) => obj?.[key], work);
};

// ---------- per-item normalization ----------

/**
 * Return a { key, display, url? } object for a single item in a list field.
 * Handles both the delta shape (snake_case, sometimes simplified) and the
 * work's GraphQL shape (camelCase, always fully structured).
 *
 * `key`     — stable string used to match an old item against a delta item
 * `display` — human-readable text rendered in the diff cell
 * `url`     — (optional) href value for related_url items
 * `itemId`  — the id the backend records this item's AI provenance under
 *             (controlled-term id, note text, url, …), so a diff cell can line
 *             each item up with its own per-item origin badge
 */
const normalizeItem = (path, item) => ({
  ...buildNormalizedItem(path, item),
  itemId: provenanceItemId(item),
});

const buildNormalizedItem = (path, item) => {
  // Controlled vocabulary fields
  // Delta:   [{term: string | {id, label}, role?}]
  // Current: [{term: {id, label}, role?}]
  if (isControlled(path)) {
    const term = item?.term;
    // Delta term supplied as a plain string — no authority id available
    if (typeof term === "string") return { key: term, display: term };
    const id = term?.id || "";
    const key = id || term?.label || "";
    return { key, display: term?.label || id || "", id };
  }

  // Coded term fields (single object, handled as scalar — shouldn't normally
  // reach here via normalizeItem, but guard for safety)
  if (isCodedTerm(path)) {
    const key = item?.id || item?.label || "";
    return { key, display: item?.label || item?.id || "" };
  }

  // Notes: [{note, type: {id, label, scheme}}]
  if (path.endsWith("notes")) {
    const key = `${item?.note || ""}|${item?.type?.id || ""}`;
    const typeLabel = item?.type?.label || "";
    const display = typeLabel
      ? `${typeLabel}: ${item?.note || ""}`
      : item?.note || "";
    return { key, display };
  }

  // Related URL: [{url, label: {id, label, scheme}}]
  if (path.endsWith("related_url")) {
    const key = item?.url || "";
    const labelText = item?.label?.label || "";
    return { key, display: labelText || item?.url || "", url: item?.url };
  }

  // date_created
  // Delta: array of EDTF strings  e.g. ["1896-11-10"]
  // Current (work): single {edtf, humanized} object — normalized to array upstream
  if (path === "descriptive_metadata.date_created") {
    if (typeof item === "string") return { key: item, display: item };
    return {
      key: item?.edtf || "",
      display: item?.humanized || item?.edtf || "",
    };
  }

  // Text arrays and generic items
  const str = String(item ?? "");
  return { key: str, display: str };
};

// ---------- diff computation ----------

/**
 * Compute a before→after diff for one change row against the work's current value.
 *
 * Returns one of:
 *   { kind: "scalar", current: string, resulting: string, changed: bool }
 *   { kind: "list",   current: [{key, display, status, url?}],
 *                     resulting: [{key, display, status, url?}] }
 *
 * `status` ∈ "unchanged" | "added" | "removed"
 */
const computeRowDiff = (row, currentValue) => {
  const { method, path, value } = row;

  // Coded term — always a single {id, label} object; render as scalar
  if (isCodedTerm(path)) {
    const renderTerm = (v) => (v ? v.label || v.id || "" : "");
    const current = renderTerm(currentValue);
    const resulting = method === "delete" ? "" : renderTerm(value);
    return {
      kind: "scalar",
      current,
      resulting,
      changed: current !== resulting,
    };
  }

  // Text-single fields and other plain scalars (non-array, non-controlled,
  // non-nested-coded) — render as scalar
  const isListField =
    isControlled(path) ||
    isNestedCodedTerm(path) ||
    isTextArray(path) ||
    Array.isArray(value) ||
    Array.isArray(currentValue);

  if (!isListField) {
    const current = currentValue != null ? String(currentValue) : "";
    const resulting =
      method === "delete" ? "" : value != null ? String(value) : "";
    return {
      kind: "scalar",
      current,
      resulting,
      changed: current !== resulting,
    };
  }

  // All list fields
  // Normalize the current (work) value to an array of items
  let rawCurrent;
  if (
    path === "descriptive_metadata.date_created" &&
    currentValue != null &&
    !Array.isArray(currentValue)
  ) {
    // Work returns a single {edtf, humanized} object; wrap it
    rawCurrent = [currentValue];
  } else {
    rawCurrent = toArray(currentValue);
  }

  const currentNorm = rawCurrent.map((item) => normalizeItem(path, item));
  const deltaNorm = toArray(value).map((item) => normalizeItem(path, item));

  const currentKeys = new Set(currentNorm.map((i) => i.key));
  const deltaKeys = new Set(deltaNorm.map((i) => i.key));

  let current, resulting;

  if (method === "add") {
    // Current side: all existing items, unchanged
    current = currentNorm.map((i) => ({ ...i, status: "unchanged" }));
    // Resulting side: existing (unchanged) + new items not already present (added)
    const added = deltaNorm
      .filter((i) => !currentKeys.has(i.key))
      .map((i) => ({ ...i, status: "added" }));
    resulting = [
      ...currentNorm.map((i) => ({ ...i, status: "unchanged" })),
      ...added,
    ];
  } else if (method === "delete") {
    // Current side: existing items; those matching the delta are marked removed
    current = currentNorm.map((i) => ({
      ...i,
      status: deltaKeys.has(i.key) ? "removed" : "unchanged",
    }));
    // Resulting side: existing items minus the deleted ones
    resulting = currentNorm
      .filter((i) => !deltaKeys.has(i.key))
      .map((i) => ({ ...i, status: "unchanged" }));
  } else {
    // replace: current → delta
    current = currentNorm.map((i) => ({
      ...i,
      status: deltaKeys.has(i.key) ? "unchanged" : "removed",
    }));
    resulting = deltaNorm.map((i) => ({
      ...i,
      status: currentKeys.has(i.key) ? "unchanged" : "added",
    }));
  }

  return { kind: "list", current, resulting };
};

/**
 * Ensure a value is an array
 */
const toArray = (v) => (Array.isArray(v) ? v : v ? [v] : []);

/**
 * Determine if a given dotted path is a controlled field
 */
const isControlled = (path) => CONTROLLED_TERM_FIELDS.has(path);

/**
 * Determine if a given dotted path is a coded term field
 */
const isCodedTerm = (path) => CODED_TERM_FIELDS.has(path);

/**
 * Determine if a given dotted path is a nested coded term field
 */
const isNestedCodedTerm = (path) => NESTED_CODED_TERM_FIELDS.has(path);

/**
 * Determine if a given dotted path is a single valued text field
 */
const isTextSingle = (path) => TEXT_SINGLE_FIELDS.has(path);

/**
 * Determine if a given dotted path is a multi valued text field
 */
const isTextArray = (path) => TEXT_ARRAY_FIELDS.has(path);

/**
 * Lookup a display label from WORK_FIELDS
 */
const getFieldLabel = (path, fields) => {
  const parts = path.split(".");
  let node = fields;
  let label = null;

  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];
    if (node && typeof node === "object" && part in node) {
      const val = node[part];
      if (typeof val === "string") {
        label = val;
      } else if (val && typeof val === "object") {
        node = val;
      }
    } else {
      break;
    }
  }

  return label || path.split(".").pop();
};

/**
 * Recursively walk a change object and produce flat table rows
 */
const toRows = (changeObj, method) => {
  const rows = [];

  const walk = (node, parentPath = "") => {
    if (!node || typeof node !== "object" || Array.isArray(node)) return;

    for (const [key, value] of Object.entries(node)) {
      const path = parentPath ? `${parentPath}.${key}` : key;

      if (isControlled(path)) {
        rows.push({
          id: `${method}-${path}`,
          method,
          path,
          label: getFieldLabel(path, WORK_FIELDS),
          value,
          controlled: true,
        });
        continue;
      }

      if (isCodedTerm(path)) {
        rows.push({
          id: `${method}-${path}`,
          method,
          path,
          label: getFieldLabel(path, WORK_FIELDS),
          value,
          controlled: false,
        });
        continue;
      }

      if (isNestedCodedTerm(path)) {
        rows.push({
          id: `${method}-${path}`,
          method,
          path,
          label: getFieldLabel(path, WORK_FIELDS),
          value,
          controlled: false,
          nestedCoded: true,
        });
        continue;
      }

      // Is a primitive value or array
      if (value == null || typeof value !== "object" || Array.isArray(value)) {
        rows.push({
          id: `${method}-${path}`,
          method,
          path,
          label: getFieldLabel(path, WORK_FIELDS),
          value,
          controlled: false,
        });
        continue;
      }

      // Nested plain object
      walk(value, path);
    }
  };

  walk(changeObj);
  return rows;
};

export {
  toArray,
  isControlled,
  isCodedTerm,
  isNestedCodedTerm,
  isTextSingle,
  isTextArray,
  getFieldLabel,
  toRows,
  snakeToCamelPath,
  getCurrentValue,
  normalizeItem,
  computeRowDiff,
};
