import React from "react";
import { Link } from "react-router-dom";
import { modelLabel, runTitle } from "./hooks";
import type { RunSummary } from "./types";

interface Props {
  runs: RunSummary[];
  onDelete: (run: RunSummary) => void;
}

const names = (items: (string | null | undefined)[]) =>
  items.filter(Boolean).join(", ");

export default function RunsTable({ runs, onDelete }: Props) {
  if (!runs.length) {
    return (
      <p className="notification is-light">
        No runs yet. Pick images, models and variants above and run them.
      </p>
    );
  }
  return (
    <div className="table-container">
      <table
        className="table is-striped is-hoverable is-fullwidth"
        data-testid="bench-runs-table"
      >
        <thead>
          <tr>
            <th>Run</th>
            <th>Images</th>
            <th>Models</th>
            <th>Variants</th>
            <th>Done</th>
            <th>Author</th>
            <th>Started</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {runs.map((run) => (
            <tr key={run.id}>
              <td>
                <Link to={`/dashboards/transcription/runs/${run.id}`}>
                  {runTitle(run)}
                </Link>
              </td>
              <td className="is-size-7">
                {names((run.images ?? []).map((image) => image.label))}
              </td>
              <td className="is-size-7">
                {names((run.models ?? []).map(modelLabel))}
              </td>
              <td className="is-size-7">
                {names((run.variants ?? []).map((variant) => variant.name))}
              </td>
              <td>
                {run.active > 0 ? (
                  <span className="tag is-info">
                    {run.total - run.active}/{run.total} running
                  </span>
                ) : (
                  <span>
                    {run.done}/{run.total}
                  </span>
                )}
                {run.cancelled > 0 && (
                  <span className="tag is-light ml-2">
                    {run.cancelled} cancelled
                  </span>
                )}
                {run.failed > 0 && (
                  <span className="tag is-danger is-light ml-2">
                    {run.failed} failed
                  </span>
                )}
              </td>
              <td className="is-size-7">{run.author}</td>
              <td className="is-size-7">
                {new Date(run.insertedAt).toLocaleString()}
              </td>
              <td>
                <div className="buttons are-small is-flex-wrap-nowrap">
                  <Link
                    to={`/dashboards/transcription/runs/${run.id}`}
                    className="button is-light"
                  >
                    View
                  </Link>
                  <button
                    type="button"
                    className="button is-danger is-light"
                    disabled={run.active > 0}
                    title={
                      run.active > 0
                        ? "A run can be deleted once it has finished"
                        : undefined
                    }
                    onClick={() => onDelete(run)}
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
