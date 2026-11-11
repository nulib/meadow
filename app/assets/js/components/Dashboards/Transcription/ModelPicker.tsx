import React, { useState } from "react";
import { useQuery } from "@apollo/client";
import { GET_TRANSCRIPTION_BENCH_MODELS } from "./transcription.gql";
import { toggle } from "./hooks";
import type { ModelInfo } from "./types";

const MODELS_SHOWN = 8;

interface Props {
  selected: string[];
  customModels: string[];
  onChange: (next: { models: string[]; customModels: string[] }) => void;
}

/** The Claude models Bedrock offers, plus any model or profile id typed in. */
export default function ModelPicker({
  selected,
  customModels,
  onChange,
}: Props) {
  const [showAll, setShowAll] = useState(false);
  const [custom, setCustom] = useState("");
  const { data, loading, error } = useQuery(GET_TRANSCRIPTION_BENCH_MODELS);
  const listed: ModelInfo[] = data?.transcriptionBenchModels ?? [];

  // A model that is ticked but not listed (typed in, or from a loaded run) still shows.
  const extra = [...new Set([...customModels, ...selected])].filter(
    (id) => !listed.some((model) => model.id === id),
  );
  const all: ModelInfo[] = [
    ...listed,
    ...extra.map((id) => ({ id, label: id })),
  ];
  const shown = showAll
    ? all
    : all.filter(
        (model, index) => index < MODELS_SHOWN || selected.includes(model.id),
      );

  const add = () => {
    const id = custom.trim();
    if (!id) return;
    onChange({
      customModels: [...new Set([...customModels, id])],
      models: [...new Set([...selected, id])],
    });
    setCustom("");
  };

  return (
    <div data-testid="bench-model-picker">
      {loading && <progress className="progress is-small is-primary" />}
      {error && (
        <p className="notification is-danger is-light">{error.message}</p>
      )}
      <ul className="bench-model-list">
        {shown.map((model) => (
          <li key={model.id}>
            <label className="checkbox">
              <input
                type="checkbox"
                checked={selected.includes(model.id)}
                onChange={() =>
                  onChange({
                    customModels,
                    models: toggle(selected, model.id),
                  })
                }
              />
              <span>{model.label}</span>
              <code>{model.id}</code>
            </label>
          </li>
        ))}
      </ul>
      <div className="field has-addons mt-3">
        {all.length > MODELS_SHOWN && (
          <div className="control">
            <button
              type="button"
              className="button is-small"
              onClick={() => setShowAll(!showAll)}
            >
              {showAll ? "Fewer" : `All ${all.length}`}
            </button>
          </div>
        )}
        <div className="control is-expanded">
          <input
            className="input is-small is-family-monospace"
            placeholder="Another model or profile id"
            aria-label="Another model or profile id"
            value={custom}
            onChange={(event) => setCustom(event.target.value)}
            onKeyDown={(event) => event.key === "Enter" && add()}
          />
        </div>
        <div className="control">
          <button
            type="button"
            className="button is-small"
            onClick={add}
            disabled={!custom.trim()}
          >
            Add
          </button>
        </div>
      </div>
    </div>
  );
}
