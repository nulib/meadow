import React from "react";
import UIControlledTermList from "@js/components/UI/ControlledTerm/List";
import { toArray, toRows } from "@js/components/Plan/Panel/diff-helpers";

/**
 * Tag indicating the method of change
 */
const MethodTag = ({ method }) => {
  let text = "";

  switch (method) {
    case "add":
      text = "Add";
      break;
    case "delete":
      text = "Delete";
      break;
    case "replace":
      text = "Replace";
      break;
    default:
      text = "";
      break;
  }

  return <span data-testid="tag">{text}</span>;
};

/**
 * Render a generic (non-controlled) value
 */
const renderGenericValue = (value) => {
  if (value == null) return "—";
  if (typeof value !== "object") return String(value);
  if (value instanceof Date) return value.toISOString();

  if (Array.isArray(value)) {
    if (value.length === 0) return "—";
    return (
      <ul>
        {value.map((v, i) => (
          <li key={i}>
            {typeof v === "object" ? JSON.stringify(v, null, 0) : String(v)}
          </li>
        ))}
      </ul>
    );
  }

  // Defensively render other objects as JSON
  return JSON.stringify(value, null, 0);
};

const PlanPanelChangesDiff = ({ proposedChanges }) => {
  const changes = [
    ...toRows(proposedChanges.add, "add"),
    ...toRows(proposedChanges.delete, "delete"),
    ...toRows(proposedChanges.replace, "replace"),
  ];

  changes.sort(
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
        {changes.map((change) => (
          <tr key={change.id} data-method={change.method}>
            <td>
              <MethodTag method={change.method} />
            </td>
            <td>{change.label}</td>
            <td>
              {change.controlled ? (
                <UIControlledTermList
                  title={change.label}
                  items={toArray(change.value)}
                />
              ) : (
                renderGenericValue(change.value)
              )}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default PlanPanelChangesDiff;
