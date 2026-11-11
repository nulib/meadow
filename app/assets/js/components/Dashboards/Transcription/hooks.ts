import { useCallback, useEffect, useState } from "react";
import type { RunSummary } from "./types";

/** State kept in localStorage: what was picked last time, nothing that has to last. */
export function useStored<T extends object>(key: string, initial: T) {
  const [value, setValue] = useState<T>(() => readStored(key, initial));
  const set = useCallback(
    (next: T | ((previous: T) => T)) =>
      setValue((previous) => {
        const resolved =
          typeof next === "function"
            ? (next as (previous: T) => T)(previous)
            : next;
        writeStored(key, resolved);
        return resolved;
      }),
    [key],
  );
  return [value, set] as const;
}

export function readStored<T extends object>(key: string, initial: T): T {
  try {
    const stored = localStorage.getItem(key);
    return stored === null ? initial : { ...initial, ...JSON.parse(stored) };
  } catch {
    return initial;
  }
}

export function writeStored<T>(key: string, value: T) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // Private windows and full storage: the choice just is not remembered.
  }
}

/** A value that settles a moment after it stops changing. */
export function useDebounced<T>(value: T, delay = 350): T {
  const [settled, setSettled] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setSettled(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  return settled;
}

export const toggle = <T>(list: T[], item: T) =>
  list.includes(item) ? list.filter((each) => each !== item) : [...list, item];

export const modelLabel = (id: string) =>
  id.replace(/^(us|global|eu|apac)\.anthropic\./, "").replace(/-\d{8}.*$/, "");

export const runTitle = (run: Pick<RunSummary, "name" | "insertedAt">) =>
  run.name || new Date(run.insertedAt).toLocaleString();

/** A IIIF Image API URL for a file set's image, or null without one. */
export function iiifUrl(base: string | null | undefined, path: string) {
  if (!base) return null;
  return `${base.replace(/\/+$/, "")}/${path.replace(/^\/+/, "")}`;
}
