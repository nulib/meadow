import React, { useState } from "react";
import UIControlledTermList from "@js/components/UI/ControlledTerm/List";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import {
  toArray,
  toRows,
  isCodedTerm,
} from "@js/components/Plan/Panel/diff-helpers";
import { IconEdit, IconDelete } from "@js/components/Icon";
import { UPDATE_PLAN_CHANGE } from "../plan.gql";
import { Button } from "@nulib/design-system";
import { useMutation } from "@apollo/client";
import EditDiffRowForm from "@js/components/Plan/Panel/EditDiffRowForm";

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
const renderNotes = (notes) => {
  if (!Array.isArray(notes) || notes.length === 0) return "—";

  return (
    <ul>
      {notes.map((note, i) => (
        <li key={i}>
          {note.type?.label && <strong>{note.type.label}: </strong>}
          {note.note || "—"}
        </li>
      ))}
    </ul>
  );
};

/**
 * Render a related_url array
 */
const renderRelatedUrls = (urls) => {
  if (!Array.isArray(urls) || urls.length === 0) return "—";

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
        </li>
      ))}
    </ul>
  );
};

/**
 * Render a nested coded term field (notes or related_url)
 */
const renderNestedCodedTerm = (path, value) => {
  if (path.endsWith("notes")) {
    return renderNotes(value);
  }
  if (path.endsWith("related_url")) {
    return renderRelatedUrls(value);
  }
  // Fallback to generic rendering
  return renderGenericValue(value);
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
            {typeof v === "object" && v !== null
              ? v.humanized || v.edtf || JSON.stringify(v, null, 0)
              : String(v)}
          </li>
        ))}
      </ul>
    );
  }

  // Defensively render other objects as JSON
  return JSON.stringify(value, null, 0);
};

const PlanPanelChangesDiff = ({ proposedChanges, planChangeId }) => {
  const [updatePlanChange] = useMutation(UPDATE_PLAN_CHANGE);
  const [editingRowId, setEditingRowId] = useState(null);
  const [deletingRowId, setDeletingRowId] = useState(null);

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

  return (
    <>
      <h3 className="mb-3">Details</h3>
      <table className="table is-fullwidth is-striped">
        <thead>
          <tr>
            <th>Type</th>
            <th>Field</th>
            <th>Proposed Value</th>
            <th>{isProposed && "Actions"}</th>
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
                ) : change.nestedCoded ? (
                  renderNestedCodedTerm(change.path, change.value)
                ) : isCodedTerm(change.path) ? (
                  renderCodedTerm(change.value)
                ) : (
                  renderGenericValue(change.value)
                )}
              </td>
              <td style={{ whiteSpace: "nowrap" }}>
                {isProposed && (
                  <>
                    {!(Array.isArray(change.value) && change.value.length === 0) && (
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
                  </>
                )}
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
            ? `${changes.find((c) => c.id === deletingRowId)?.label || 'this field'} from plan changes`
            : ''
        }
      />
    </>
  );
};

export default PlanPanelChangesDiff;
