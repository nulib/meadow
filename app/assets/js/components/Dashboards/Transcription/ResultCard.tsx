import Viewer from "@nulib/clover";
import { Default } from "@nulib/clover/templates";
import React, {
  memo,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { modelLabel } from "./hooks";
import { annotationPages, manifestOf, resultKey } from "./manifest";
import type { Result, Variant } from "./types";

interface Props {
  runId: string;
  result: Result;
  variant: Variant | undefined;
  /** Viewer over JSON, for cards side by side; else viewer beside JSON. */
  stacked: boolean;
  /** The DC API token the IIIF server wants for images that are not public. */
  token: string | undefined;
  onRetry: (resultId: string) => void;
  onCancel: (resultId: string) => void;
}

const PANEL_SECTIONS = ["annotations"] as const;
const number = (value: number | null | undefined) =>
  (value ?? 0).toLocaleString("en-US");

/** Mounts its children once it nears the viewport: a run can hold ten viewers. */
function Lazy({
  children,
  className,
}: {
  children: ReactNode;
  className: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [seen, setSeen] = useState(false);
  useEffect(() => {
    if (seen || !ref.current) return;
    if (typeof IntersectionObserver === "undefined") {
      setSeen(true);
      return;
    }
    const observer = new IntersectionObserver(
      (entries) =>
        entries.some((entry) => entry.isIntersecting) && setSeen(true),
      { rootMargin: "600px" },
    );
    observer.observe(ref.current);
    return () => observer.disconnect();
  }, [seen]);
  return (
    <div ref={ref} className={className}>
      {seen && children}
    </div>
  );
}

function Elapsed({ since }: { since: string | null | undefined }) {
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);
  if (!since) return null;
  return <>{Math.max(0, Math.round((now - Date.parse(since)) / 1000))}s</>;
}

function Stat({
  label,
  children,
  warn,
}: {
  label?: string;
  children: ReactNode;
  warn?: boolean;
}) {
  return (
    <span
      className={`bench-stat ${warn ? "has-text-warning-dark has-text-weight-semibold" : ""}`}
    >
      {label && <span className={warn ? "" : "has-text-grey"}>{label} </span>}
      {children}
    </span>
  );
}

type Tab = "annotations" | "output" | "text" | "request" | "reasoning";

function pretty(text: string) {
  try {
    return JSON.stringify(JSON.parse(text), null, 2);
  } catch {
    return text;
  }
}

function JsonPane({
  result,
  annotations,
}: {
  result: Result;
  annotations: unknown;
}) {
  const [tab, setTab] = useState<Tab>("annotations");
  const [copied, setCopied] = useState(false);
  const tabs: [Tab, string][] = [
    ["annotations", "Annotations"],
    ["output", "Model output"],
    ["text", "Text"],
    ["request", "Request"],
  ];
  if (result.reasoning) tabs.push(["reasoning", "Reasoning"]);

  const content = useMemo(() => {
    switch (tab) {
      case "annotations":
        return JSON.stringify(annotations, null, 2);
      case "output":
        return pretty(result.toolInput || result.text || "");
      case "text":
        return result.parsed?.text ?? "";
      case "request":
        return JSON.stringify(result.request ?? null, null, 2);
      case "reasoning":
        return result.reasoning ?? "";
    }
  }, [tab, annotations, result]);

  const copy = async () => {
    await navigator.clipboard.writeText(content);
    setCopied(true);
    setTimeout(() => setCopied(false), 1200);
  };

  const prose = tab === "text" || tab === "reasoning";
  return (
    <div className="bench-json">
      <div role="tablist" className="bench-json-tabs">
        {tabs.map(([value, label]) => (
          <button
            key={value}
            type="button"
            role="tab"
            aria-selected={tab === value}
            onClick={() => setTab(value)}
          >
            {label}
          </button>
        ))}
        <button type="button" className="bench-json-copy" onClick={copy}>
          {copied ? "Copied" : "Copy"}
        </button>
      </div>
      <pre tabIndex={0} className={prose ? "is-prose" : ""}>
        {content || <span className="bench-json-empty">Nothing here.</span>}
      </pre>
    </div>
  );
}

function ResultCardInner({
  runId,
  result,
  variant,
  stacked,
  token,
  onRetry,
  onCancel,
}: Props) {
  const done = result.status === "done";
  const key = resultKey(result);
  const pages = useMemo(
    () => (done ? annotationPages(runId, result) : []),
    // A finished result never changes; run again, it has a new attempt.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [runId, key, done],
  );
  const manifest = useMemo(
    () => (done ? manifestOf(runId, result, pages) : null),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [runId, key, done, pages],
  );
  const request = useMemo(
    () =>
      token ? { headers: { Authorization: `Bearer ${token}` } } : undefined,
    [token],
  );

  const regions = result.parsed?.regions ?? [];
  const unboxed = regions.filter((region) => !region.box).length;
  const levels = (result.parsed?.levels ?? []).map(
    (level) =>
      `${number(regions.filter((region) => region.level === level).length)} ${level}`,
  );
  const stopped =
    result.stopReason && !["tool_use", "end_turn"].includes(result.stopReason);
  // The model resized what it was sent, so its boxes are pixels of a smaller image.
  const resized =
    !!result.processedWidth &&
    !!result.processedHeight &&
    (result.processedWidth !== result.sentWidth ||
      result.processedHeight !== result.sentHeight);
  const noToolCall =
    done && variant?.outputMode === "tool" && !result.toolInput;

  return (
    <article className="bench-result" data-testid="bench-result">
      <header className="bench-result-header">
        <h4 className="has-text-weight-semibold">{modelLabel(result.model)}</h4>
        <span className="tag is-primary is-light">
          {variant?.name ?? result.variantId}
        </span>
        <span className="bench-result-stats">
          {done && (
            <>
              <Stat>{levels.length ? levels.join(" · ") : "no regions"}</Stat>
              {unboxed > 0 && <Stat warn>{number(unboxed)} without a box</Stat>}
              <Stat label="chars">{number(result.parsed?.text?.length)}</Stat>
              <Stat label="tokens">
                {number(result.usage?.inputTokens)} in /{" "}
                {number(result.usage?.outputTokens)} out
              </Stat>
              <Stat label="time">
                {((result.durationMs ?? 0) / 1000).toFixed(1)}s
              </Stat>
              {result.sentWidth && result.sentHeight && (
                <Stat label="sent">
                  {result.sentWidth} × {result.sentHeight}
                </Stat>
              )}
              {resized && (
                <Stat label="resized by the model to" warn>
                  {result.processedWidth} × {result.processedHeight}
                </Stat>
              )}
              {stopped && (
                <Stat label="stopped:" warn>
                  {result.stopReason}
                </Stat>
              )}
              {noToolCall && <Stat warn>no tool call</Stat>}
            </>
          )}
          {(result.status === "queued" || result.status === "running") && (
            <button
              type="button"
              className="button is-small is-danger is-light"
              onClick={() => onCancel(result.id)}
            >
              Cancel
            </button>
          )}
          {(done ||
            result.status === "error" ||
            result.status === "cancelled") && (
            <button
              type="button"
              className="button is-small"
              onClick={() => onRetry(result.id)}
            >
              Run again
            </button>
          )}
        </span>
      </header>

      {result.status === "queued" && (
        <p className="bench-result-waiting has-text-grey">Queued</p>
      )}
      {result.status === "running" && (
        <p className="bench-result-waiting">
          <span className="loader is-inline-block mr-2" />
          Transcribing, <Elapsed since={result.startedAt} />
        </p>
      )}
      {result.status === "cancelled" && (
        <p className="bench-result-waiting has-text-grey">
          Cancelled. Nothing was kept of this transcription.
        </p>
      )}
      {result.status === "error" && (
        <p className="notification is-danger is-light bench-result-error">
          {result.error}
        </p>
      )}
      {done &&
        (result.parsed?.warnings ?? []).map((warning) => (
          <p key={warning} className="bench-result-warning">
            {warning}
          </p>
        ))}
      {done && manifest && (
        <div className={`bench-result-body ${stacked ? "is-stacked" : ""}`}>
          <Lazy className="bench-viewer">
            {request ? (
              <Viewer
                key={key}
                iiifContent={manifest}
                template={Default}
                request={request}
                header={false}
                items={false}
                panelLayout="tabs"
                panelSections={PANEL_SECTIONS}
                defaultPanelOpen
                storageKey={false}
                headingLevel={5}
                fill
              />
            ) : null}
          </Lazy>
          <JsonPane
            result={result}
            annotations={pages.length === 1 ? pages[0] : pages}
          />
        </div>
      )}
    </article>
  );
}

export default memo(
  ResultCardInner,
  (previous, next) =>
    previous.runId === next.runId &&
    previous.result.id === next.result.id &&
    previous.result.attempt === next.result.attempt &&
    previous.result.status === next.result.status &&
    previous.stacked === next.stacked &&
    previous.token === next.token &&
    previous.onRetry === next.onRetry &&
    previous.onCancel === next.onCancel &&
    previous.variant?.name === next.variant?.name,
);
