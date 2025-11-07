import { Tag, Button, Icon } from "@nulib/design-system";
import React, { useState } from "react";
import { useMutation } from "@apollo/client";
import UIControlledTermList from "@js/components/UI/ControlledTerm/List";
import { toArray } from "@js/components/Plan/Panel/diff-helpers";
import { UPDATE_PLAN_CHANGE } from "@js/components/Plan/plan.gql.js";
import TextEditor from "./Editors/TextEditor";
import ArrayEditor from "./Editors/ArrayEditor";
import ControlledTermEditor from "./Editors/ControlledTermEditor";

/**
 * Tag indicating the method of change
 */
const MethodTag = ({ method }) => {
  let tagProps = {};
  let text = "";

  switch (method) {
    case "add":
      tagProps = { isSuccess: true };
      text = "Add";
      break;
    case "delete":
      tagProps = { isDanger: true };
      text = "Delete";
      break;
    case "replace":
      tagProps = { isInfo: true };
      text = "Replace";
      break;
    default:
      tagProps = {};
      text = "";
      break;
  }

  return (
    <Tag as="span" {...tagProps}>
      {text}
    </Tag>
  );
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

/**
 * Reconstruct nested object from dot-separated path string
 * e.g., "descriptive_metadata.title" => { descriptive_metadata: { title: value } }
 */
const reconstructFromPath = (pathString, value) => {
  const path = pathString.split(".");
  if (path.length === 0) return value;
  if (path.length === 1) return { [path[0]]: value };

  const [first, ...rest] = path;
  return { [first]: reconstructFromPath(rest.join("."), value) };
};

/**
 * Single editable row in the diff table
 */
const DiffRow = ({ change, planChangeId, allProposedChanges }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editedValue, setEditedValue] = useState(change.value);
  const [updatePlanChange, { loading, error }] = useMutation(
    UPDATE_PLAN_CHANGE,
  );

  const handleEdit = () => {
    setEditedValue(change.value);
    setIsEditing(true);
  };

  const handleCancel = () => {
    setEditedValue(change.value);
    setIsEditing(false);
  };

  const handleSave = async () => {
    try {
      // Reconstruct the nested object for this specific field
      const fieldUpdate = reconstructFromPath(change.path, editedValue);

      // Build the variables object with the updated method
      const variables = {
        id: planChangeId,
      };

      // We need to merge with existing values for other fields in the same method
      // Get all current changes for this method
      const currentMethodChanges = allProposedChanges[change.method] || {};

      // Merge the new value into existing changes
      const mergedChanges = {
        ...currentMethodChanges,
        ...fieldUpdate,
      };

      // Add the appropriate field (add/replace/delete) as a JSON string
      variables[change.method] = JSON.stringify(mergedChanges);

      const result = await updatePlanChange({
        variables,
        // Refetch to ensure we get the latest data with proper structure
        refetchQueries: ["planChanges"],
        awaitRefetchQueries: true,
      });

      console.log("Mutation result:", result);
      console.log("Mutation variables sent:", variables);
      console.log("Parsed back:", {
        method: change.method,
        parsedValue: JSON.parse(variables[change.method]),
      });
      setIsEditing(false);
    } catch (err) {
      console.error("Failed to update plan change:", err);
    }
  };

  const renderEditor = () => {
    if (change.controlled) {
      return (
        <ControlledTermEditor value={editedValue} onChange={setEditedValue} />
      );
    } else if (Array.isArray(change.value)) {
      return <ArrayEditor value={editedValue} onChange={setEditedValue} />;
    } else {
      return <TextEditor value={editedValue} onChange={setEditedValue} />;
    }
  };

  const renderValue = () => {
    if (change.controlled) {
      const items = toArray(change.value);

      // Log for debugging
      console.log("Rendering controlled terms:", {
        label: change.label,
        rawItems: items,
        changeValue: change.value,
      });

      // Ensure each item has proper term structure
      const normalizedItems = items
        .map((item, idx) => {
          if (!item || typeof item !== "object") {
            console.warn(`Item ${idx} is not an object:`, item);
            return null;
          }

          if (!item.term) {
            console.warn(`Item ${idx} missing term:`, item);
            return null;
          }

          // Ensure term has at least an id
          if (!item.term.id) {
            console.warn(`Item ${idx} term missing id:`, item);
            return null;
          }

          const normalized = {
            ...item,
            term: {
              id: item.term.id,
              label: item.term.label || item.term.id, // Fallback to ID if no label
            },
          };

          console.log(`Normalized item ${idx}:`, normalized);
          return normalized;
        })
        .filter(Boolean); // Remove nulls

      console.log("Final normalized items:", normalizedItems);

      if (normalizedItems.length === 0) {
        return <p className="help is-warning">No valid terms to display</p>;
      }

      return (
        <UIControlledTermList title={change.label} items={normalizedItems} />
      );
    }
    return renderGenericValue(change.value);
  };

  return (
    <tr key={change.id} data-method={change.method}>
      <td>
        <MethodTag method={change.method} />
      </td>
      <td>{change.label}</td>
      <td>
        {isEditing ? (
          <div>
            {renderEditor()}
            {error && (
              <p className="help is-danger">
                Error saving: {error.message}
              </p>
            )}
            <div className="buttons mt-2">
              <Button
                isPrimary
                isSmall
                onClick={handleSave}
                isLoading={loading}
                disabled={loading}
              >
                <Icon>
                  <span className="material-icons">save</span>
                </Icon>
                <span>Save</span>
              </Button>
              <Button isSmall onClick={handleCancel} disabled={loading}>
                <Icon>
                  <span className="material-icons">close</span>
                </Icon>
                <span>Cancel</span>
              </Button>
            </div>
          </div>
        ) : (
          <div>
            {renderValue()}
            <Button
              isSmall
              isText
              onClick={handleEdit}
              className="mt-2"
              title="Edit this field"
            >
              <Icon>
                <span className="material-icons">edit</span>
              </Icon>
              <span>Edit</span>
            </Button>
          </div>
        )}
      </td>
    </tr>
  );
};

export default DiffRow;
