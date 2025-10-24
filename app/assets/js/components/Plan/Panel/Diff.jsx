import { Button } from "@nulib/design-system";
import React from "react";

const PlanPanelChangesDiff = ({ proposedChanges }) => {
  const addEntries = proposedChanges.add
    ? Object.entries(proposedChanges.add)
    : [];
  const deleteEntries = proposedChanges.delete
    ? Object.entries(proposedChanges.delete)
    : [];
  const replaceEntries = proposedChanges.replace
    ? Object.entries(proposedChanges.replace)
    : [];

  return (
    <div>
      <h3 className="title is-4 mb-3">Proposed Changes</h3>
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
              <td>{JSON.stringify(value)}</td>
            </tr>
          ))}
          {deleteEntries.map(([field, value]) => (
            <tr key={`delete-${field}`}>
              <td>Delete</td>
              <td>{field}</td>
              <td>{JSON.stringify(value)}</td>
            </tr>
          ))}
          {replaceEntries.map(([field, value]) => (
            <tr key={`replace-${field}`}>
              <td>Replace</td>
              <td>{field}</td>
              <td>{JSON.stringify(value)}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <Button isPrimary={true}>Approve Changes</Button>
    </div>
  );
};

export default PlanPanelChangesDiff;
