import React from "react";
import { toRows } from "@js/components/Plan/Panel/diff-helpers";
import DiffRow from "./DiffRow";

const PlanPanelChangesDiff = ({ proposedChanges, planChangeId }) => {
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
          <DiffRow
            key={change.id}
            change={change}
            planChangeId={planChangeId}
            allProposedChanges={proposedChanges}
          />
        ))}
      </tbody>
    </table>
  );
};

export default PlanPanelChangesDiff;
