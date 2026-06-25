import React, { useState } from "react";
import UIControlledTermList from "@js/components/UI/ControlledTerm/List";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import {
  toArray,
  toRows,
  isCodedTerm,
  getCurrentValue,
  computeRowDiff,
} from "@js/components/Plan/Panel/diff-helpers";
import { IconEdit, IconDelete } from "@js/components/Icon";
import { UPDATE_PLAN_CHANGE, GET_PLAN_CHANGE_PROVENANCE } from "../plan.gql";
import { Button } from "@nulib/design-system";
import { useMutation, useQuery } from "@apollo/client/react";
import EditDiffRowForm from "@js/components/Plan/Panel/EditDiffRowForm";
import {
  OriginBadge,
  ProvenancePreviewBadge,
  provenanceItemId,
  valueItemIds,
} from "@js/components/AIProvenance/Badges";

// Origins that signal a human has already shaped the value; these win over a
// less-specific recorded origin when more than one target exists for a field.
const HUMAN_TOUCHED = [
  "ai_assisted_human_modified",
  "human_replacement_after_ai_suggestion",
  "human_generated",
];

/**
 * Map field_path -> recorded origin for a plan change's provenance targets,
 * preferring an origin that reflects a human edit when several exist.
 */
function recordedOriginByPath(activities = []) {
  const map = {};
  activities.forEach((activity) => {
    (activity.targets || []).forEach((target) => {
      const existing = map[target.fieldPath];
      if (!existing || HUMAN_TOUCHED.includes(target.origin)) {
        map[target.fieldPath] = target.origin;
      }
    });
  });
  return map;
}

/**
 * Map field_path -> per-item AI attribution, taken straight from the backend's
 * reconciled `itemProvenance` (the AI's proposal diffed against the current
 * value). Using the server-computed attribution keeps the plan diff and the
 * work About tab in lock-step rather than re-deriving it here.
 */
function itemProvenanceByPath(activities = []) {
  const map = {};
  activities.forEach((activity) => {
    (activity.targets || []).forEach((target) => {
      map[target.fieldPath] = target.itemProvenance || [];
    });
  });
  return map;
}

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
 * Render a coded term value (rights_statement, license)
 */
const renderCodedTerm = (value) => {
  if (!value || typeof value !== "object") return "—";

  // Show label if available, otherwise show id
  if (value.label) return value.label;
  if (value.id) return value.id;

  return JSON.stringify(value, null, 0);
};

/**
 * Render a notes array
 */
const renderNotes = (notes, itemProvenance = []) => {
  if (!Array.isArray(notes) || notes.length === 0) return "—";

  const originById = originLookup(itemProvenance);

  return (
    <ul>
      {notes.map((note, i) => (
        <li key={i}>
          {note.type?.label && <strong>{note.type.label}: </strong>}
          {note.note || "—"}
          <ItemOriginBadge origin={originById[provenanceItemId(note)]} />
        </li>
      ))}
    </ul>
  );
};

/**
 * Render a related_url array
 */
const renderRelatedUrls = (urls, itemProvenance = []) => {
  if (!Array.isArray(urls) || urls.length === 0) return "—";

  const originById = originLookup(itemProvenance);

  return (
    <ul>
      {urls.map((item, i) => (
        <li key={i}>
          {item.label?.label && <strong>{item.label.label}: </strong>}
          {item.url ? (
            <a href={item.url} target="_blank" rel="noopener noreferrer">
              {item.url}
            </a>
          ) : (
            "—"
          )}
          <ItemOriginBadge origin={originById[provenanceItemId(item)]} />
        </li>
      ))}
    </ul>
  );
};

/**
 * Render a nested coded term field (notes or related_url)
 */
const renderNestedCodedTerm = (path, value, itemProvenance = []) => {
  if (path.endsWith("notes")) {
    return renderNotes(value, itemProvenance);
  }
  if (path.endsWith("related_url")) {
    return renderRelatedUrls(value, itemProvenance);
  }
  // Fallback to generic rendering
  return renderGenericValue(value, itemProvenance);
};

/**
 * Map of item id -> AI origin for a field's per-item provenance, so each value
 * can look up its own attribution.
 */
const originLookup = (itemProvenance = []) =>
  itemProvenance.reduce((acc, entry) => {
    if (entry?.id) acc[entry.id] = entry.origin;
    return acc;
  }, {});

/**
 * Inline per-item origin badge, or nothing when the item carries no AI origin.
 */
const ItemOriginBadge = ({ origin }) =>
  origin ? (
    <span className="ml-2">
      <OriginBadge origin={origin} />
    </span>
  ) : null;

/**
 * Whether any item in a (possibly array) value carries per-item AI provenance,
 * so callers can skip the field-level preview badge once items are badged
 * individually.
 */
const hasItemProvenance = (value, itemProvenance = []) => {
  if (!Array.isArray(value) || !itemProvenance.length) return false;
  const ids = new Set(itemProvenance.map((entry) => entry?.id));
  return valueItemIds(value).some((id) => ids.has(id));
};

/**
 * Render a generic (non-controlled) value. For multivalued fields, each item
 * the AI proposed is badged individually (via itemProvenance) so reviewers can
 * see attribution per value rather than one badge for the whole field.
 */
const renderGenericValue = (value, itemProvenance = []) => {
  if (value == null) return "—";
  if (typeof value !== "object") return String(value);
  if (value instanceof Date) return value.toISOString();

  if (Array.isArray(value)) {
    if (value.length === 0) return "—";
    const originById = originLookup(itemProvenance);
    return (
      <ul>
        {value.map((v, i) => (
          <li key={i}>
            {typeof v === "object" && v !== null
              ? v.humanized || v.edtf || JSON.stringify(v, null, 0)
              : String(v)}
            <ItemOriginBadge origin={originById[provenanceItemId(v)]} />
          </li>
        ))}
      </ul>
    );
  }

  // Defensively render other objects as JSON
  return JSON.stringify(value, null, 0);
};

/**
 * Render a list of diff items ({key, display, status, url?}) for one cell in
 * the approved diff table.  Items are marked added, removed, or unchanged.
 */
const DiffItemList = ({ items }) => {
  if (!items || items.length === 0) {
    return <span>—</span>;
  }
  return (
    <ul>
      {items.map((item, i) => (
        <li key={item.key || i} data-diff-status={item.status}>
          {item.url ? (
            <a href={item.url} target="_blank" rel="noopener noreferrer">
              {item.display || item.url}
            </a>
          ) : (
            item.display || "—"
          )}
          {item.id && item.id !== item.display && (
            <span className="plan-diff-term-id"> ({item.id})</span>
          )}
        </li>
      ))}
    </ul>
  );
};

const PlanPanelChangesDiff = ({
  proposedChanges,
  planChangeId,
  currentWork,
}) => {
  // Editing/deleting a row records a manual edit on the backend (the target's
  // origin becomes ai_assisted_human_modified / human_replacement_after_ai_suggestion),
  // so refetch the provenance to keep the preview badges in sync.
  const [updatePlanChange] = useMutation(UPDATE_PLAN_CHANGE, {
    awaitRefetchQueries: true,
    refetchQueries: planChangeId
      ? [{ query: GET_PLAN_CHANGE_PROVENANCE, variables: { planChangeId } }]
      : [],
  });
  const [editingRowId, setEditingRowId] = useState(null);
  const [deletingRowId, setDeletingRowId] = useState(null);

  const { data: provenanceData } = useQuery(GET_PLAN_CHANGE_PROVENANCE, {
    variables: { planChangeId },
    skip: !planChangeId,
  });
  const recordedOrigins = recordedOriginByPath(provenanceData?.aiActivities);
  const itemProvenances = itemProvenanceByPath(provenanceData?.aiActivities);

  const isProposed = proposedChanges?.status === "PROPOSED";

  const removeFieldFromProposedChanges = (id) => {
    const [method, path] = id.split("-");

    const methodChanges = JSON.parse(
      JSON.stringify(proposedChanges[method] || {}),
    );
    const pathSegments = path.split(".");
    let current = methodChanges;

    for (let i = 0; i < pathSegments.length - 1; i++) {
      const key = pathSegments[i];
      if (typeof current[key] === "undefined" || current[key] === null) {
        return;
      }
      current = current[key];
    }

    const finalKey = pathSegments[pathSegments.length - 1];
    if (typeof current[finalKey] !== "undefined") {
      delete current[finalKey];
    }

    return {
      ...proposedChanges,
      [method]: methodChanges,
    };
  };

  const formatUpdates = (updatedPlanChangeForMethod) => {
    return Object.keys(updatedPlanChangeForMethod || {}).length > 0
      ? JSON.stringify(updatedPlanChangeForMethod)
      : null;
  };

  const handleDeletePlanChangeRow = async (id) => {
    if (!id) {
      console.error("Cannot delete: id is null or undefined");
      return;
    }

    const updatedPlanChange = removeFieldFromProposedChanges(id);

    try {
      await updatePlanChange({
        variables: {
          id: planChangeId,
          add: formatUpdates(updatedPlanChange.add),
          replace: formatUpdates(updatedPlanChange.replace),
          delete: formatUpdates(updatedPlanChange.delete),
        },
      });
    } catch (e) {
      console.error("Error deleting plan change row:", e);
    }
    setDeletingRowId(null);
  };

  const handleSaveClick = async (changeId, newValue) => {
    // Parse the changeId to get method and path
    const [method, path] = changeId.split("-");

    // Update the proposedChanges structure
    const updatedChanges = JSON.parse(JSON.stringify(proposedChanges));

    // Navigate to the field and update it (path already exists since we're editing an existing row)
    const pathSegments = path.split(".");
    let current = updatedChanges[method];

    // Navigate to the parent
    for (let i = 0; i < pathSegments.length - 1; i++) {
      current = current[pathSegments[i]];
    }

    // Update the value, or delete the field if the new value is an empty array
    const finalSegment = pathSegments[pathSegments.length - 1];
    if (Array.isArray(newValue) && newValue.length === 0) {
      delete current[finalSegment];
    } else {
      current[finalSegment] = newValue;
    }

    try {
      await updatePlanChange({
        variables: {
          id: planChangeId,
          add: updatedChanges.add && formatUpdates(updatedChanges.add),
          replace:
            updatedChanges.replace && formatUpdates(updatedChanges.replace),
          delete: updatedChanges.delete && formatUpdates(updatedChanges.delete),
        },
      });

      setEditingRowId(null);
    } catch (e) {
      console.error("Error saving plan change:", e);
    }
  };
  const handleCancelClick = () => {
    setEditingRowId(null);
  };
  const handleEditClick = (id) => {
    setEditingRowId(id);
  };
  const handleDeleteClick = (id) => {
    setDeletingRowId(id);
  };

  const onCloseModal = () => {
    setDeletingRowId(null);
  };

  const changes = [
    ...toRows(proposedChanges.add, "add"),
    ...toRows(proposedChanges.delete, "delete"),
    ...toRows(proposedChanges.replace, "replace"),
  ];

  changes.sort(
    (a, b) =>
      a.label.localeCompare(b.label) || a.method.localeCompare(b.method),
  );

  // After Approve: show a before→after diff table (read-only)
  if (!isProposed) {
    return (
      <>
        <h3 className="mb-3">Details</h3>
        <table className="table is-fullwidth is-striped plan-diff-table">
          <thead>
            <tr>
              <th>Field</th>
              <th>Type</th>
              <th>Current value</th>
              <th>New value</th>
            </tr>
          </thead>
          <tbody>
            {changes.map((change) => {
              const currentValue = getCurrentValue(change.path, currentWork);
              const diff = computeRowDiff(change, currentValue);
              return (
                <tr key={change.id} data-method={change.method}>
                  <td>{change.label}</td>
                  <td>
                    <MethodTag method={change.method} />
                  </td>
                  <td>
                    {diff.kind === "list" ? (
                      <DiffItemList items={diff.current} />
                    ) : (
                      <span>{diff.current || "—"}</span>
                    )}
                  </td>
                  <td>
                    {diff.kind === "list" ? (
                      <DiffItemList items={diff.resulting} />
                    ) : (
                      <span data-diff-changed={diff.changed}>
                        {diff.resulting || "—"}
                      </span>
                    )}
                    <ProvenancePreviewBadge
                      method={change.method}
                      currentValue={currentValue}
                      recordedOrigin={recordedOrigins[change.path]}
                    />
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </>
    );
  }

  // PROPOSED phase: existing editable table with per-row edit/delete actions
  return (
    <>
      <h3 className="mb-3">Details</h3>
      <table className="table is-fullwidth is-striped">
        <thead>
          <tr>
            <th>Type</th>
            <th>Field</th>
            <th>Proposed Value</th>
            <th>Actions</th>
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
                    itemProvenance={itemProvenances[change.path]}
                  />
                ) : change.nestedCoded ? (
                  renderNestedCodedTerm(
                    change.path,
                    change.value,
                    itemProvenances[change.path],
                  )
                ) : isCodedTerm(change.path) ? (
                  renderCodedTerm(change.value)
                ) : (
                  renderGenericValue(change.value, itemProvenances[change.path])
                )}
                {/* Controlled fields badge their AI-suggested items
                    individually via UIControlledTermList; multivalued
                    non-controlled fields badge their items via
                    renderGenericValue. Either way, skip the field-level
                    preview badge once items are badged individually to avoid
                    a duplicate. */}
                {!change.controlled &&
                  !hasItemProvenance(
                    change.value,
                    itemProvenances[change.path],
                  ) && (
                    <ProvenancePreviewBadge
                      method={change.method}
                      currentValue={getCurrentValue(change.path, currentWork)}
                      recordedOrigin={recordedOrigins[change.path]}
                    />
                  )}
              </td>
              <td style={{ whiteSpace: "nowrap" }}>
                {!(
                  Array.isArray(change.value) && change.value.length === 0
                ) && (
                  <Button
                    onClick={() => handleEditClick(change.id)}
                    data-testid="button-edit-plan-change-row"
                  >
                    <IconEdit />
                  </Button>
                )}
                <Button
                  onClick={() => handleDeleteClick(change.id)}
                  data-testid="button-delete-plan-change-row"
                >
                  <IconDelete />
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      <EditDiffRowForm
        change={changes.find((c) => c.id === editingRowId)}
        isOpen={!!editingRowId}
        onSave={handleSaveClick}
        onCancel={handleCancelClick}
      />
      <UIModalDelete
        isOpen={!!deletingRowId}
        handleClose={onCloseModal}
        handleConfirm={() => handleDeletePlanChangeRow(deletingRowId)}
        thingToDeleteLabel={
          deletingRowId
            ? `${changes.find((c) => c.id === deletingRowId)?.label || "this field"} from plan changes`
            : ""
        }
      />
    </>
  );
};

export default PlanPanelChangesDiff;
