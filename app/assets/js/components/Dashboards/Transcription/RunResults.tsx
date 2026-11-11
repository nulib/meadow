import React, { useState } from "react";
import { modelLabel, runTitle, toggle } from "./hooks";
import ResultCard from "./ResultCard";
import type { Run } from "./types";

interface Props {
  run: Run;
  columns: number;
  token: string | undefined;
  onColumns: (columns: number) => void;
  onRetry: (resultId: string) => void;
  onCancel: (resultId: string) => void;
  onCancelRun: () => void;
  onUseSetup: () => void;
  onDelete: () => void;
}

/** Meadow's CSV downloads are form posts to /api, so the session cookie goes along. */
function downloadCsv(run: Run, kind: "results" | "regions") {
  const form = document.createElement("form");
  form.method = "POST";
  form.action = `/api/transcription_bench/${encodeURIComponent(
    `transcription_bench_${run.id}_${kind}.csv`,
  )}`;
  for (const [name, value] of [
    ["run_id", run.id],
    ["kind", kind],
  ]) {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    form.appendChild(input);
  }
  document.body.appendChild(form);
  form.submit();
  document.body.removeChild(form);
}

function downloadJson(run: Run) {
  const url = URL.createObjectURL(
    new Blob([JSON.stringify(run, null, 1)], { type: "application/json" }),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download = `transcription_bench_${run.id}.json`;
  link.click();
  URL.revokeObjectURL(url);
}

function Filter({
  label,
  options,
  hidden,
  onToggle,
}: {
  label: string;
  options: { id: string; label: string }[];
  hidden: string[];
  onToggle: (id: string) => void;
}) {
  if (options.length < 2) return null;
  return (
    <div className="bench-filter">
      <span className="heading mb-0">{label}</span>
      {options.map((option) => {
        const shown = !hidden.includes(option.id);
        return (
          <button
            key={option.id}
            type="button"
            aria-pressed={shown}
            onClick={() => onToggle(option.id)}
            className={`tag is-clickable ${shown ? "is-primary is-light" : "is-hidden-result"}`}
          >
            {option.label}
          </button>
        );
      })}
    </div>
  );
}

export default function RunResults({
  run,
  columns,
  token,
  onColumns,
  onRetry,
  onCancel,
  onCancelRun,
  onUseSetup,
  onDelete,
}: Props) {
  const [hidden, setHidden] = useState<string[]>([]);
  const flip = (id: string) => setHidden((previous) => toggle(previous, id));

  const results = run.results ?? [];
  const variants = run.variants ?? [];
  const finished = results.filter(
    (result) => result.status !== "queued" && result.status !== "running",
  ).length;
  const cancelled = results.filter(
    (result) => result.status === "cancelled",
  ).length;
  const failed = results.filter((result) => result.status === "error").length;
  const variantOf = (id: string) =>
    variants.find((variant) => variant.id === id);
  const shown = results.filter(
    (result) =>
      !hidden.includes(`image:${result.fileSetId}`) &&
      !hidden.includes(`model:${result.model}`) &&
      !hidden.includes(`variant:${result.variantId}`),
  );

  // The run's images in order, plus any a result names that the run's list does not.
  const images = [...(run.images ?? [])];
  for (const result of results) {
    if (!images.some((image) => image.fileSetId === result.fileSetId)) {
      images.push({ fileSetId: result.fileSetId, label: result.label });
    }
  }

  return (
    <div data-testid="bench-run-results">
      <div className="level">
        <div className="level-left">
          <div className="level-item is-block">
            <h1 className="title is-4 mb-1">{runTitle(run)}</h1>
            <p className="is-size-7 has-text-grey">
              {run.name && `${new Date(run.insertedAt).toLocaleString()} · `}
              {run.author && `${run.author} · `}
              {finished} of {results.length} finished
              {failed > 0 && (
                <span className="has-text-danger"> · {failed} failed</span>
              )}
              {cancelled > 0 && ` · ${cancelled} cancelled`}
            </p>
          </div>
        </div>
        <div className="level-right">
          <div className="level-item buttons are-small has-addons mb-0 mr-3">
            <span className="button is-static">Columns</span>
            {[1, 2, 3].map((count) => (
              <button
                key={count}
                type="button"
                aria-pressed={columns === count}
                onClick={() => onColumns(count)}
                className={`button ${columns === count ? "is-primary" : ""}`}
              >
                {count}
              </button>
            ))}
          </div>
          <div className="level-item buttons are-small mb-0">
            {finished < results.length && (
              <button
                type="button"
                className="button is-danger is-light"
                onClick={onCancelRun}
              >
                Cancel run
              </button>
            )}
            <button type="button" className="button" onClick={onUseSetup}>
              Load this setup
            </button>
            <button
              type="button"
              className="button"
              onClick={() => downloadCsv(run, "results")}
            >
              Results CSV
            </button>
            <button
              type="button"
              className="button"
              onClick={() => downloadCsv(run, "regions")}
            >
              Regions CSV
            </button>
            <button
              type="button"
              className="button"
              onClick={() => downloadJson(run)}
            >
              JSON
            </button>
            <button
              type="button"
              className="button is-danger is-light"
              onClick={onDelete}
            >
              Delete
            </button>
          </div>
        </div>
      </div>

      <div className="bench-filters">
        <Filter
          label="Images"
          hidden={hidden}
          onToggle={flip}
          options={images.map((image) => ({
            id: `image:${image.fileSetId}`,
            label: image.label || image.fileSetId,
          }))}
        />
        <Filter
          label="Models"
          hidden={hidden}
          onToggle={flip}
          options={(run.models ?? []).map((model) => ({
            id: `model:${model}`,
            label: modelLabel(model),
          }))}
        />
        <Filter
          label="Variants"
          hidden={hidden}
          onToggle={flip}
          options={variants.map((variant) => ({
            id: `variant:${variant.id}`,
            label: variant.name,
          }))}
        />
      </div>

      {images.map((image) => {
        const ofImage = shown.filter(
          (result) => result.fileSetId === image.fileSetId,
        );
        if (!ofImage.length) return null;
        return (
          <section key={image.fileSetId} className="mb-5">
            <h2 className="subtitle is-6 mb-2">
              {image.label || image.fileSetId}
            </h2>
            <div
              className="bench-results-grid"
              style={{
                gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))`,
              }}
            >
              {ofImage.map((result) => (
                <ResultCard
                  key={result.id}
                  runId={run.id}
                  result={result}
                  variant={variantOf(result.variantId)}
                  stacked={columns > 1}
                  token={token}
                  onRetry={onRetry}
                  onCancel={onCancel}
                />
              ))}
            </div>
          </section>
        );
      })}
      {!shown.length && (
        <p className="has-text-centered has-text-grey py-6">
          Every result is filtered out.
        </p>
      )}
    </div>
  );
}
