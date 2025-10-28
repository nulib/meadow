import React from "react";

const flattenObject = (obj, parentKey = "") => {
  const result = {};
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

const PlanPanelChangesDiff = ({ proposedChanges }) => {
  const addEntries = proposedChanges.add
    ? Object.entries(flattenObject(proposedChanges.add))
    : [];
  const deleteEntries = proposedChanges.delete
    ? Object.entries(flattenObject(proposedChanges.delete))
    : [];
  const replaceEntries = proposedChanges.replace
    ? Object.entries(flattenObject(proposedChanges.replace))
    : [];

  return (
    <table className="table is-fullwidth is-striped">
      <thead>
        <tr>
          <th>Status</th>
          <th>Field</th>
          <th>Proposed Value</th>
        </tr>
      </thead>
      <tbody>
        {addEntries.map(([field, value]) => (
          <tr key={`add-${field}`}>
            <td>Add</td>
            <td>{field}</td>
            <td>{Array.isArray(value) ? value.join(", ") : String(value)}</td>
          </tr>
        ))}
        {deleteEntries.map(([field, value]) => (
          <tr key={`delete-${field}`}>
            <td>Delete</td>
            <td>{field}</td>
            <td>{Array.isArray(value) ? value.join(", ") : String(value)}</td>
          </tr>
        ))}
        {replaceEntries.map(([field, value]) => (
          <tr key={`replace-${field}`}>
            <td>Replace</td>
            <td>{field}</td>
            <td>{Array.isArray(value) ? value.join(", ") : String(value)}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default PlanPanelChangesDiff;
