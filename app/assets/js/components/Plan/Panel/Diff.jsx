import { Tag } from "@nulib/design-system";
import React from "react";
import { WORK_FIELDS } from "../fields";

const flattenObject = (obj, parentKey = "") => {
  const result = {};
  if (!obj || typeof obj !== "object") return result;

  for (const [key, value] of Object.entries(obj)) {
    const newKey = parentKey ? `${parentKey}.${key}` : key;

    if (value && typeof value === "object" && !Array.isArray(value)) {
      Object.assign(result, flattenObject(value, newKey));
    } else {
      result[newKey] = value;
    }
  }
  return result;
};

const humanize = (s) =>
  s
    .split(".")
    .pop()
    .replace(/[_-]+/g, " ")
    .replace(/\w\S*/g, (w) => w.charAt(0).toUpperCase() + w.slice(1));

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

  return label || humanize(path);
};

const summarizeObject = (obj) => {
  if (!obj || typeof obj !== "object") return String(obj);

  const role =
    obj.role?.label || obj.role?.id || obj.role || obj.scheme || null;
  const term = obj.term?.label || obj.term?.id || obj.term || obj.value || null;

  if (role || term) {
    if (role && term) return `${String(role)}: ${String(term)}`;
    if (term) return String(term);
    if (role) return String(role);
  }

  if (obj.label && obj.id) return `${obj.label} (${obj.id})`;
  if (obj.label) return String(obj.label);
  if (obj.id) return String(obj.id);

  try {
    const json = JSON.stringify(obj);
    return json.length > 140 ? json.slice(0, 137) + "…" : json;
  } catch {
    return String(obj);
  }
};

const formatValue = (value) => {
  if (value == null) return "—";

  if (typeof value !== "object") return String(value);
  if (value instanceof Date) return value.toISOString();

  if (Array.isArray(value)) {
    if (value.length === 0) return "—";

    return (
      <ul className="list-disc list-inside m-0 p-0">
        {value.map((v, i) => (
          <li key={i}>
            {typeof v === "object" ? summarizeObject(v) : String(v)}
          </li>
        ))}
      </ul>
    );
  }

  return summarizeObject(value);
};

const toRows = (changeObj, method) => {
  if (!changeObj) return [];
  const flat = flattenObject(changeObj);
  return Object.entries(flat).map(([path, value]) => ({
    id: `${method}-${path}`,
    method,
    path,
    label: getFieldLabel(path, WORK_FIELDS),
    value,
  }));
};

const MethodTag = ({ method }) => {
  if (method === "add")
    return (
      <Tag isSuccess as="span">
        Add
      </Tag>
    );
  if (method === "delete")
    return (
      <Tag isDanger as="span">
        Delete
      </Tag>
    );
  return (
    <Tag isInfo as="span">
      Replace
    </Tag>
  );
};

const PlanPanelChangesDiff = ({ proposedChanges }) => {
  const rows = [
    ...toRows(proposedChanges.add, "add"),
    ...toRows(proposedChanges.delete, "delete"),
    ...toRows(proposedChanges.replace, "replace"),
  ];

  rows.sort(
    (a, b) =>
      a.label.localeCompare(b.label) || a.method.localeCompare(b.method),
  );

  return (
    <table className="table is-fullwidth is-striped">
      <thead>
        <tr>
          <th>Type</th>
          <th>Field</th>
          <th>Proposed Value</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((r) => (
          <tr key={r.id} data-method={r.method}>
            <td>
              <MethodTag method={r.method} />
            </td>
            <td>{r.label}</td>
            <td>{formatValue(r.value)}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default PlanPanelChangesDiff;
