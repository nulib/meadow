import React, { useState } from "react";
import { Button, Icon } from "@nulib/design-system";

/**
 * Controlled term editor for vocabulary fields
 * For now, this is a simplified version that allows editing term URIs directly
 * In production, this could integrate with authority search
 */
const ControlledTermEditor = ({ value, onChange }) => {
  const items = Array.isArray(value) ? value : value ? [value] : [];
  const [newTermId, setNewTermId] = useState("");

  const handleAdd = () => {
    if (newTermId.trim()) {
      // Check if existing items have a role field and use it as template
      const existingRole = items.length > 0 && items[0].role ? items[0].role : null;

      const newTerm = {
        ...(existingRole ? { role: existingRole } : {}),
        term: { id: newTermId.trim() },
      };
      onChange([...items, newTerm]);
      setNewTermId("");
    }
  };

  const handleRemove = (index) => {
    const filtered = items.filter((_, i) => i !== index);
    // Always call onChange with the filtered array, even if empty
    onChange(filtered.length > 0 ? filtered : []);
  };

  const handleUpdate = (index, newTermId) => {
    // If the term ID is empty or whitespace, remove this item instead of updating
    if (!newTermId.trim()) {
      handleRemove(index);
      return;
    }

    const updated = [...items];
    const existingItem = updated[index];

    // Preserve the role if it exists, otherwise omit it
    updated[index] = {
      ...(existingItem.role ? { role: existingItem.role } : {}),
      term: { id: newTermId.trim() },
    };

    onChange(updated);
  };

  const getTermId = (item) => {
    if (!item) return "";
    if (typeof item === "string") return item;
    if (item.term && item.term.id) return item.term.id;
    return "";
  };

  return (
    <div className="controlled-term-editor">
      {items.map((item, index) => {
        const termId = getTermId(item);
        const termLabel = item?.term?.label;

        return (
          <div key={index} className="mb-2">
            <div className="field has-addons">
              <div className="control is-expanded">
                <input
                  type="text"
                  className="input"
                  placeholder="Authority URI (e.g., http://id.loc.gov/authorities/...)"
                  value={termId}
                  onChange={(e) => handleUpdate(index, e.target.value)}
                />
              </div>
              <div className="control">
                <Button
                  isText
                  onClick={() => handleRemove(index)}
                  title="Remove term"
                >
                  <Icon className="icon is-small">
                    <span className="material-icons">close</span>
                  </Icon>
                </Button>
              </div>
            </div>
            {termLabel && (
              <p className="help is-success">Label: {termLabel}</p>
            )}
            {termId && !termLabel && (
              <p className="help">
                Note: URI will be displayed until label is resolved
              </p>
            )}
          </div>
        );
      })}
      <div className="field has-addons">
        <div className="control is-expanded">
          <input
            type="text"
            className="input"
            placeholder="http://id.loc.gov/authorities/subjects/sh85..."
            value={newTermId}
            onChange={(e) => setNewTermId(e.target.value)}
            onKeyPress={(e) => {
              if (e.key === "Enter") {
                e.preventDefault();
                handleAdd();
              }
            }}
          />
        </div>
        <div className="control">
          <Button isPrimary onClick={handleAdd}>
            Add
          </Button>
        </div>
      </div>
      <p className="help">
        Note: Use the authority URI without .html extension (e.g., http://id.loc.gov/authorities/subjects/sh85030813)
      </p>
    </div>
  );
};

export default ControlledTermEditor;
