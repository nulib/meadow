import React, { type ReactNode } from "react";
import type { Variant } from "./types";

interface Props {
  variant: Variant;
  preset?: Variant;
  onChange: (variant: Variant) => void;
  onDuplicate: () => void;
  onDelete: () => void;
}

function jsonError(text: string, allowEmpty = false): string | null {
  if (!text.trim()) return allowEmpty ? null : "Empty";
  try {
    // The placeholders stand for numbers and a name: fill them so they parse.
    JSON.parse(text.replace(/\{\{(width|height)\}\}/g, "0"));
    return null;
  } catch (error) {
    return (error as Error).message;
  }
}

function Field({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className="field">
      <label className="label is-small">
        {label}
        <span className="control is-block mt-1">{children}</span>
      </label>
      {hint && <p className="help">{hint}</p>}
    </div>
  );
}

function Group({ title, children }: { title: string; children: ReactNode }) {
  return (
    <fieldset className="bench-variant-group">
      <legend className="has-text-weight-semibold is-size-6">{title}</legend>
      {children}
    </fieldset>
  );
}

const rows = (text: string, min: number, max: number) =>
  Math.max(min, Math.min(max, text.split("\n").length + 1));

const MONO = "textarea is-small is-family-monospace";

export default function VariantEditor({
  variant,
  preset,
  onChange,
  onDuplicate,
  onDelete,
}: Props) {
  const set = <K extends keyof Variant>(key: K, value: Variant[K]) =>
    onChange({ ...variant, [key]: value });
  const schemaError =
    variant.outputMode === "tool" ? jsonError(variant.toolSchema) : null;
  const extraError = jsonError(variant.additionalFields, true);
  const changed = preset && JSON.stringify(preset) !== JSON.stringify(variant);

  const format = () => {
    try {
      set(
        "toolSchema",
        JSON.stringify(JSON.parse(variant.toolSchema), null, 2),
      );
    } catch {
      // Left as typed until it parses.
    }
  };

  return (
    <div className="bench-variant-editor" data-testid="bench-variant-editor">
      <Field label="Name">
        <input
          className="input is-small"
          value={variant.name}
          onChange={(event) => set("name", event.target.value)}
        />
      </Field>
      <Field label="Notes">
        <textarea
          className="textarea is-small"
          rows={2}
          value={variant.notes}
          placeholder="What this variant is trying"
          onChange={(event) => set("notes", event.target.value)}
        />
      </Field>

      <Group title="Prompt">
        <Field
          label="User prompt"
          hint={
            <>
              Sent after the image. <code>{"{{width}}"}</code> and{" "}
              <code>{"{{height}}"}</code> are the size of the image sent,{" "}
              <code>{"{{tool_name}}"}</code> the tool's name. They work in the
              tool description and schema too.
            </>
          }
        >
          <textarea
            className={MONO}
            rows={rows(variant.prompt, 8, 28)}
            spellCheck={false}
            value={variant.prompt}
            onChange={(event) => set("prompt", event.target.value)}
          />
        </Field>
        <Field
          label="System prompt"
          hint="Optional. The transcriber sends none."
        >
          <textarea
            className={MONO}
            rows={rows(variant.system, 2, 12)}
            spellCheck={false}
            value={variant.system}
            onChange={(event) => set("system", event.target.value)}
          />
        </Field>
      </Group>

      <Group title="Structured output">
        <div className="columns is-mobile mb-0">
          <div className="column">
            <Field label="Answer as">
              <span className="select is-small is-fullwidth">
                <select
                  value={variant.outputMode}
                  onChange={(event) =>
                    set(
                      "outputMode",
                      event.target.value as Variant["outputMode"],
                    )
                  }
                >
                  <option value="tool">A tool call</option>
                  <option value="text">Text (JSON or plain)</option>
                </select>
              </span>
            </Field>
          </div>
          <div className="column">
            {variant.outputMode === "tool" && (
              <Field label="Tool choice">
                <span className="select is-small is-fullwidth">
                  <select
                    value={variant.toolChoice}
                    onChange={(event) =>
                      set(
                        "toolChoice",
                        event.target.value as Variant["toolChoice"],
                      )
                    }
                  >
                    <option value="auto">auto (the prompt asks)</option>
                    <option value="any">any (forced)</option>
                    <option value="tool">this tool (forced)</option>
                  </select>
                </span>
              </Field>
            )}
          </div>
        </div>
        {variant.outputMode === "tool" ? (
          <>
            <Field label="Tool name">
              <input
                className="input is-small is-family-monospace"
                value={variant.toolName}
                onChange={(event) => set("toolName", event.target.value)}
              />
            </Field>
            <Field label="Tool description">
              <textarea
                className={MONO}
                rows={rows(variant.toolDescription, 3, 10)}
                spellCheck={false}
                value={variant.toolDescription}
                onChange={(event) => set("toolDescription", event.target.value)}
              />
            </Field>
            <div className="field">
              <div className="level is-mobile mb-1">
                <span className="level-left label is-small mb-0">
                  Input schema (JSON Schema)
                </span>
                <span className="level-right">
                  {schemaError ? (
                    <span className="is-size-7 has-text-danger mr-2">
                      Not valid JSON
                    </span>
                  ) : (
                    <span className="is-size-7 has-text-success mr-2">
                      Valid JSON
                    </span>
                  )}
                  <button
                    type="button"
                    className="button is-small is-text"
                    onClick={format}
                  >
                    Format
                  </button>
                </span>
              </div>
              <textarea
                aria-label="Input schema"
                className={`${MONO} ${schemaError ? "is-danger" : ""}`}
                rows={rows(variant.toolSchema, 10, 30)}
                spellCheck={false}
                value={variant.toolSchema}
                onChange={(event) => set("toolSchema", event.target.value)}
              />
              {schemaError && <p className="help is-danger">{schemaError}</p>}
              <p className="help">
                Any array of objects with a <code>text</code> becomes a level of
                regions, named by its key; a nested array (a line's{" "}
                <code>words</code>) is a nested level. A region's box is read
                from <code>box</code> or <code>bbox</code>.
              </p>
            </div>
          </>
        ) : (
          <p className="help">
            No tool is sent. The answer is read as JSON when it is JSON (bare,
            or in a code fence), in the same shapes a tool input is; otherwise
            as plain text.
          </p>
        )}
      </Group>

      <Group title="How boxes are read">
        <div className="columns is-mobile mb-0">
          <div className="column">
            <Field label="Numbers">
              <span className="select is-small is-fullwidth">
                <select
                  value={variant.boxOrder}
                  onChange={(event) =>
                    set("boxOrder", event.target.value as Variant["boxOrder"])
                  }
                >
                  <option value="xyxy">[x_min, y_min, x_max, y_max]</option>
                  <option value="xywh">[x, y, width, height]</option>
                  <option value="yxyx">[y_min, x_min, y_max, x_max]</option>
                </select>
              </span>
            </Field>
          </div>
          <div className="column">
            <Field label="Counted in">
              <span className="select is-small is-fullwidth">
                <select
                  value={variant.boxUnits}
                  onChange={(event) =>
                    set("boxUnits", event.target.value as Variant["boxUnits"])
                  }
                >
                  <option value="px">Pixels of the image</option>
                  <option value="1000">A 0 to 1000 grid (not advised)</option>
                  <option value="frac">Fractions, 0 to 1 (not advised)</option>
                </select>
              </span>
            </Field>
          </div>
        </div>
        <p className="help">
          This has to match what the prompt and schema ask for. Eight numbers
          are read as the four corners of a quadrilateral. Claude answers best
          in pixels, and its pixels are those of the image as it processed it: a
          result is read against that size, which its card shows when it is not
          the size sent.
        </p>
      </Group>

      <Group title="Image and request">
        <div className="columns is-mobile mb-0">
          <div className="column">
            <Field
              label="Image sent"
              hint="A model resizes an image over its limits and answers in pixels of the resized one. Resizing it first keeps the size sent, the size in the prompt and the size of the boxes the same."
            >
              <span className="select is-small is-fullwidth">
                <select
                  value={variant.imageFit ?? "production"}
                  onChange={(event) =>
                    set("imageFit", event.target.value as Variant["imageFit"])
                  }
                >
                  <option value="production">
                    As the transcriber sends it (longest edge below)
                  </option>
                  <option value="model">
                    Resized to what the model processes
                  </option>
                </select>
              </span>
            </Field>
          </div>
          <div className="column">
            <Field
              label="Model's image limits"
              hint="Standard: 1568 px, 1568 visual tokens. High resolution: 2576 px, 4784 tokens (Claude 4.7 and later)."
            >
              <span className="select is-small is-fullwidth">
                <select
                  value={variant.imageTier ?? "auto"}
                  onChange={(event) =>
                    set("imageTier", event.target.value as Variant["imageTier"])
                  }
                >
                  <option value="auto">By model</option>
                  <option value="standard">Standard</option>
                  <option value="high">High resolution</option>
                </select>
              </span>
            </Field>
          </div>
        </div>
        <div className="columns is-mobile mb-0">
          <div className="column">
            <Field
              label="Longest edge (px)"
              hint="Asked of the IIIF server. The transcriber sends 2048."
            >
              <input
                type="number"
                className="input is-small"
                min={256}
                max={8000}
                step={64}
                value={variant.maxEdge}
                onChange={(event) =>
                  set("maxEdge", Number(event.target.value) || 2048)
                }
              />
            </Field>
          </div>
          <div className="column">
            <Field label="Max tokens" hint="At most 64000.">
              <input
                type="number"
                className="input is-small"
                min={256}
                max={64000}
                step={1000}
                value={variant.maxTokens}
                onChange={(event) =>
                  set("maxTokens", Number(event.target.value) || 64000)
                }
              />
            </Field>
          </div>
          <div className="column">
            <Field
              label="Temperature"
              hint="Empty leaves it out; current models reject it."
            >
              <input
                type="number"
                className="input is-small"
                min={0}
                max={1}
                step={0.1}
                value={variant.temperature ?? ""}
                placeholder="not sent"
                onChange={(event) =>
                  set(
                    "temperature",
                    event.target.value === ""
                      ? null
                      : Number(event.target.value),
                  )
                }
              />
            </Field>
          </div>
        </div>
        <Field
          label="Additional model request fields (JSON)"
          hint={
            extraError ? (
              <span className="has-text-danger">{extraError}</span>
            ) : (
              <>
                Passed as Converse's <code>additionalModelRequestFields</code>,
                for thinking, effort and the like.
              </>
            )
          }
        >
          <textarea
            className={`${MONO} ${extraError ? "is-danger" : ""}`}
            rows={rows(variant.additionalFields, 2, 10)}
            spellCheck={false}
            placeholder='{"thinking": {"type": "adaptive"}}'
            value={variant.additionalFields}
            onChange={(event) => set("additionalFields", event.target.value)}
          />
        </Field>
      </Group>

      <div className="level is-mobile mt-4">
        <div className="level-left buttons are-small mb-0">
          <button type="button" className="button" onClick={onDuplicate}>
            Duplicate
          </button>
          {changed && preset && (
            <button
              type="button"
              className="button"
              onClick={() => onChange(preset)}
            >
              Reset to preset
            </button>
          )}
        </div>
        <div className="level-right">
          <button
            type="button"
            className="button is-small is-danger is-light"
            onClick={onDelete}
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  );
}
