import React, { useState } from "react";
import { Button, Icon } from "@nulib/design-system";

/**
 * Array editor for multi-value string fields
 */
const ArrayEditor = ({ value, onChange }) => {
  const items = Array.isArray(value) ? value : value ? [value] : [];
  const [newItem, setNewItem] = useState("");

  const handleAdd = () => {
    if (newItem.trim()) {
      onChange([...items, newItem.trim()]);
      setNewItem("");
    }
  };

  const handleRemove = (index) => {
    onChange(items.filter((_, i) => i !== index));
  };

  const handleUpdate = (index, newValue) => {
    const updated = [...items];
    updated[index] = newValue;
    onChange(updated);
  };

  return (
    <div className="array-editor">
      {items.map((item, index) => (
        <div key={index} className="field has-addons mb-2">
          <div className="control is-expanded">
            <input
              type="text"
              className="input"
              value={typeof item === "object" ? JSON.stringify(item) : item}
              onChange={(e) => handleUpdate(index, e.target.value)}
            />
          </div>
          <div className="control">
            <Button
              isText
              onClick={() => handleRemove(index)}
              title="Remove item"
            >
              <Icon className="icon is-small">
                <span className="material-icons">close</span>
              </Icon>
            </Button>
          </div>
        </div>
      ))}
      <div className="field has-addons">
        <div className="control is-expanded">
          <input
            type="text"
            className="input"
            placeholder="Add new item..."
            value={newItem}
            onChange={(e) => setNewItem(e.target.value)}
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
    </div>
  );
};

export default ArrayEditor;
