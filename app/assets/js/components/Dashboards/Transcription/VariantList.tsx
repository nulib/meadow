import React, { useState } from "react";
import { PRESETS } from "./presets";
import { toggle } from "./hooks";
import VariantEditor from "./VariantEditor";
import type { Variant } from "./types";

interface Props {
  variants: Variant[];
  selected: string[];
  onChange: (next: { variants: Variant[]; selected: string[] }) => void;
}

/** The variants, to tick the ones to run and to open one for editing. */
export default function VariantList({ variants, selected, onChange }: Props) {
  const [editing, setEditing] = useState<string | null>(null);

  const add = (from?: Variant) => {
    const source =
      from ?? variants.find((variant) => variant.id === editing) ?? variants[0];
    if (!source) return;
    const id = `v-${Date.now().toString(36)}`;
    const copy = { ...source, id, name: `${source.name} (copy)` };
    const at = variants.findIndex((variant) => variant.id === source.id);
    onChange({
      variants: [...variants.slice(0, at + 1), copy, ...variants.slice(at + 1)],
      selected: [...selected, id],
    });
    setEditing(id);
  };

  const missing = PRESETS.filter(
    (preset) => !variants.some((variant) => variant.id === preset.id),
  );

  return (
    <div data-testid="bench-variant-list">
      <div className="level is-mobile mb-2">
        <p className="level-left is-size-7 has-text-grey">
          A variant is a prompt, its structured output and the image settings.
          Changes are kept in this browser as you type.
        </p>
        <div className="level-right buttons are-small mb-0">
          {missing.length > 0 && (
            <button
              type="button"
              className="button"
              onClick={() =>
                onChange({ variants: [...variants, ...missing], selected })
              }
            >
              Restore presets
            </button>
          )}
          <button type="button" className="button" onClick={() => add()}>
            + New
          </button>
        </div>
      </div>
      <ul className="bench-variant-list">
        {variants.map((variant) => {
          const open = editing === variant.id;
          return (
            <li key={variant.id} className={open ? "is-open" : ""}>
              <div className="bench-variant-row">
                <input
                  type="checkbox"
                  aria-label={`Run ${variant.name}`}
                  checked={selected.includes(variant.id)}
                  onChange={() =>
                    onChange({
                      variants,
                      selected: toggle(selected, variant.id),
                    })
                  }
                />
                <button
                  type="button"
                  className="bench-variant-name"
                  aria-expanded={open}
                  onClick={() => setEditing(open ? null : variant.id)}
                >
                  <strong>{variant.name}</strong>
                  {variant.notes && !open && (
                    <span className="is-size-7 has-text-grey">
                      {variant.notes}
                    </span>
                  )}
                </button>
                <button
                  type="button"
                  className="button is-small"
                  onClick={() => setEditing(open ? null : variant.id)}
                >
                  {open ? "Close" : "Edit"}
                </button>
              </div>
              {open && (
                <VariantEditor
                  variant={variant}
                  preset={PRESETS.find((preset) => preset.id === variant.id)}
                  onChange={(next) =>
                    onChange({
                      variants: variants.map((each) =>
                        each.id === next.id ? next : each,
                      ),
                      selected,
                    })
                  }
                  onDuplicate={() => add(variant)}
                  onDelete={() => {
                    onChange({
                      variants: variants.filter(
                        (each) => each.id !== variant.id,
                      ),
                      selected: selected.filter((id) => id !== variant.id),
                    });
                    setEditing(null);
                  }}
                />
              )}
            </li>
          );
        })}
      </ul>
    </div>
  );
}
