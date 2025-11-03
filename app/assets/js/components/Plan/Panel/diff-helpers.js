import {
  WORK_FIELDS,
  CONTROLLED_TERM_FIELDS,
} from "@js/components/Plan/fields";

/**
 * Ensure a value is an array
 */
const toArray = (v) => (Array.isArray(v) ? v : v ? [v] : []);

/**
 * Determine if a given dotted path is a controlled field
 */
const isControlled = (path) => CONTROLLED_TERM_FIELDS.has(path);

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

export { toArray, isControlled, getFieldLabel, toRows };
