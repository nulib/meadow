import React, { useState } from "react";
import { MAX_TRANSCRIPTIONS, arithmetic, type RunSize } from "./limits";

interface Props {
  size: RunSize;
  onRun: (name: string) => Promise<void>;
}

/** The run's name, its size spelled out, and the button that starts it. */
export default function RunBar({ size, onRun }: Props) {
  const [name, setName] = useState("");
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const blocked = !size.runnable || size.overCap || starting;

  const run = async () => {
    if (blocked) return;
    setStarting(true);
    setError(null);
    try {
      await onRun(name.trim());
      setName("");
    } catch (failure) {
      setError((failure as Error).message);
    } finally {
      setStarting(false);
    }
  };

  return (
    <div data-testid="bench-run-bar">
      <div className="field is-grouped">
        <div className="control is-expanded">
          <input
            className="input"
            placeholder="Name this run (optional)"
            aria-label="Run name"
            value={name}
            onChange={(event) => setName(event.target.value)}
            onKeyDown={(event) => event.key === "Enter" && run()}
          />
        </div>
        <div className="control">
          <button
            type="button"
            className={`button is-primary ${starting ? "is-loading" : ""}`}
            disabled={blocked}
            onClick={run}
          >
            {size.runnable
              ? `Run ${size.total} transcription${size.total === 1 ? "" : "s"}`
              : "Pick an image, a model and a variant"}
          </button>
        </div>
      </div>
      {size.overCap ? (
        <p className="notification is-warning is-light" role="alert">
          {arithmetic(size)}. A run is capped at {MAX_TRANSCRIPTIONS} to keep
          costs bounded: untick something.
        </p>
      ) : (
        <p className="help">
          {arithmetic(size)}. A run holds at most {MAX_TRANSCRIPTIONS}.
        </p>
      )}
      {error && (
        <p className="notification is-danger is-light" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
