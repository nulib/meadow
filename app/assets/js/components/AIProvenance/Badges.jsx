import React from "react";
import PropTypes from "prop-types";
import { useAIProvenanceBadges } from "@js/context/ai-provenance-context";

/**
 * Shared display helpers for AI provenance data exposed by Meadow's
 * `ai_provenance_summary` GraphQL field and the `ai_activities` query.
 *
 * Origin describes where a value came from in the AI-assisted workflow;
 * status describes where it sits in the proposed -> reviewed -> applied
 * lifecycle. Both are plain strings on the backend.
 *
 * Origin badges are a neutral light-grey pill with dark text and a small
 * colored dot (rendered via the `.provenance-badge::before` pseudo-element,
 * fed the `--provenance-dot` custom property) for at-a-glance identification,
 * using Meadow's toned-down secondary palette. Status pills stay full-color
 * Bulma tags.
 */

// Dot palette drawn from Meadow's secondary colors (see
// styles/scss/_variables.scss), chosen so the hues read as semantically
// meaningful and stay easy to tell apart at dot size. No purple by request.
const DOT = {
  blue: "#5091cd", // AI authored
  teal: "#007fa4", // AI edited an existing value
  brightGreen: "#58b947", // AI-assisted, human-touched
  green: "#008656", // human-owned
  amber: "#d9c826", // legacy AI note, worth attention
  grey: "#716c6b", // neutral / human / legacy
};

// Origins read as a spectrum from machine to human, with no alarm colors:
// cool blues for AI-authored content, greens once a human is involved (a
// lighter green for AI-assisted edits, a deeper green once a human owns the
// value), amber to flag a legacy AI note, and neutral grey for human/legacy.
export const ORIGIN_META = {
  ai_generated: { label: "AI generated", color: DOT.blue },
  ai_modified_human_content: { label: "AI edited", color: DOT.teal },
  ai_assisted_human_modified: {
    label: "AI + human edited",
    color: DOT.brightGreen,
  },
  human_replacement_after_ai_suggestion: {
    label: "Human replaced AI",
    color: DOT.green,
  },
  human_attested_after_ai: {
    label: "Human attested",
    color: DOT.green,
  },
  human_generated: { label: "Human", color: DOT.grey },
  legacy_ai_note_detected: { label: "Legacy AI note", color: DOT.amber },
  human_or_legacy: { label: "Human / legacy", color: DOT.grey },
};

// Status stays a full-color Bulma badge — it marks where a value sits in the
// proposed -> reviewed -> applied lifecycle and reads well as a solid color.
export const STATUS_META = {
  proposed: { label: "Proposed", className: "is-warning" },
  reviewed: { label: "Reviewed", className: "is-info" },
  applied: { label: "Applied", className: "is-success" },
  rejected: { label: "Rejected", className: "is-danger" },
  failed: { label: "Failed", className: "is-danger" },
  legacy: { label: "Legacy", className: "is-light" },
};

function humanize(value) {
  if (!value) return "";
  return value
    .toString()
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

export function OriginBadge({ origin, title }) {
  const { visible } = useAIProvenanceBadges();
  if (!visible) return null;
  if (!origin) return null;
  const meta = ORIGIN_META[origin] || {
    label: humanize(origin),
    color: "#716c6b",
  };
  return (
    <span
      className="tag provenance-badge"
      style={{ "--provenance-dot": meta.color }}
      data-testid="provenance-origin-badge"
      title={title || meta.label}
    >
      {meta.label}
    </span>
  );
}

OriginBadge.propTypes = {
  origin: PropTypes.string,
  title: PropTypes.string,
};

export function StatusPill({ status }) {
  const { visible } = useAIProvenanceBadges();
  if (!visible) return null;
  if (!status) return null;
  const meta = STATUS_META[status] || {
    label: humanize(status),
    className: "is-light",
  };
  return (
    <span
      className={`tag ${meta.className}`}
      data-testid="provenance-status-pill"
    >
      {meta.label}
    </span>
  );
}

StatusPill.propTypes = {
  status: PropTypes.string,
};

/**
 * Resolve the origin to badge for a file set annotation (e.g. a transcription).
 * Prefers the recorded AI provenance origin (AI generated, AI + human edited,
 * …); falls back to "human_generated" for a saved annotation that carries no AI
 * provenance — i.e. one a person authored or pasted in directly. Returns null
 * for an empty/unsaved annotation so nothing is badged before there is content.
 */
export function annotationOrigin(annotation) {
  if (!annotation || annotation.status !== "completed") return null;
  if (annotation.aiProvenance?.origin) return annotation.aiProvenance.origin;
  return "human_generated";
}

/**
 * Origin badge for a file set annotation, derived from its (possibly absent) AI
 * provenance. Renders nothing until the annotation is a saved, completed value.
 */
export function AnnotationOriginBadge({ annotation }) {
  const origin = annotationOrigin(annotation);
  if (!origin) return null;
  return (
    <OriginBadge
      origin={origin}
      title={provenanceTooltip(annotation?.aiProvenance) || undefined}
    />
  );
}

AnnotationOriginBadge.propTypes = {
  annotation: PropTypes.object,
};

// Statuses whose value is no longer the field's live value, so an inline
// field badge would be stale (e.g. a "Human replaced AI" tag lingering on a
// field whose AI content was removed). The full history still surfaces these
// in the Provenance tab's activity log.
const INACTIVE_FIELD_STATUSES = ["deleted", "rejected", "failed"];

/**
 * Inline badge for a single metadata field, given its provenance summary
 * entry (or undefined). Renders nothing when there is no provenance, or when
 * the recorded value is no longer live (deleted/rejected/failed), so it is
 * safe to drop next to any field. Shared by the Core and Controlled metadata
 * sections of the About tab.
 */
export function FieldProvenanceBadge({ entry }) {
  if (!entry) return null;
  if (INACTIVE_FIELD_STATUSES.includes(entry.status)) return null;
  return (
    <span className="ml-2">
      <OriginBadge origin={entry.origin} title={provenanceTooltip(entry)} />
    </span>
  );
}

FieldProvenanceBadge.propTypes = {
  entry: PropTypes.object,
};

function hasValue(value) {
  if (value === null || value === undefined) return false;
  if (typeof value === "string") return value.trim() !== "";
  if (Array.isArray(value)) return value.length > 0;
  if (typeof value === "object") return Object.keys(value).length > 0;
  return true;
}

// Origins that mean a human has already taken a hand in the value, so they win
// over any apply-time generation/modification prediction.
const HUMAN_TOUCHED_ORIGINS = [
  "ai_assisted_human_modified",
  "human_replacement_after_ai_suggestion",
  "human_generated",
];

/**
 * Predict the origin a proposed plan-change operation will be recorded with,
 * mirroring the backend rule: an AI `replace`/`delete` over a non-empty prior
 * value is a modification of human content; everything else is generation.
 */
export function predictedOrigin(method, currentValue) {
  const overwritesExisting =
    (method === "replace" || method === "delete") && hasValue(currentValue);
  return overwritesExisting ? "ai_modified_human_content" : "ai_generated";
}

/**
 * Resolve the origin to preview for a proposed change. If provenance already
 * records a human edit of the AI suggestion, that wins (the value is no longer
 * purely AI's). Otherwise predict the apply-time generation-vs-modification
 * classification from the operation and the current value being overwritten.
 */
export function previewOrigin({ recordedOrigin, method, currentValue }) {
  if (HUMAN_TOUCHED_ORIGINS.includes(recordedOrigin)) return recordedOrigin;
  return predictedOrigin(method, currentValue);
}

const PREVIEW_TITLES = {
  ai_generated: "Provenance preview: new AI-generated value",
  ai_modified_human_content:
    "Provenance preview: this AI change overwrites an existing value",
  ai_assisted_human_modified:
    "Provenance preview: AI suggestion edited by a reviewer",
  human_replacement_after_ai_suggestion:
    "Provenance preview: reviewer replacement of an AI suggestion",
};

/**
 * Preview badge for the approval/diff view: shows the provenance a proposed AI
 * change *will* be recorded with before it is applied — net-new ("AI
 * generated"), overwriting existing content ("AI edited"), or already edited by
 * a reviewer ("AI + human edited") — so reviewers can catch AI-assisted edits
 * they may want to drop.
 */
export function ProvenancePreviewBadge({
  method,
  currentValue,
  recordedOrigin,
}) {
  const origin = previewOrigin({ recordedOrigin, method, currentValue });
  return (
    <span className="is-block mt-1" data-testid="provenance-preview">
      <OriginBadge
        origin={origin}
        title={PREVIEW_TITLES[origin] || "Provenance preview"}
      />
    </span>
  );
}

ProvenancePreviewBadge.propTypes = {
  method: PropTypes.string,
  currentValue: PropTypes.any,
  recordedOrigin: PropTypes.string,
};

/**
 * Extract item identifiers (controlled-term ids or plain strings) from a
 * possibly-wrapped provenance value (`{ value: [...] }` or a bare array).
 * Mirrors the backend so the plan diff can attribute AI items per term.
 */
export function valueItemIds(value) {
  const list = value && value.value !== undefined ? value.value : value;
  if (!Array.isArray(list)) return [];
  return list.map(provenanceItemId).filter(Boolean);
}

/**
 * Unwrap a stored provenance value. Targets and events persist values wrapped
 * as `{ value: ... }`; callers may also pass a bare value.
 */
function unwrapProvenanceValue(value) {
  return value && value.value !== undefined ? value.value : value;
}

/**
 * Identifier for a single value item, used to line a displayed value up with its
 * per-item AI provenance entry. Mirrors the backend's `item_identifier`: a
 * controlled-term id, a note's text, a related_url's url, a plain id, or the
 * string itself. Shared by valueItemIds and every per-item renderer so the id a
 * value is badged by always matches the id the backend recorded.
 */
export function provenanceItemId(item) {
  if (item == null) return null;
  if (typeof item === "string") return item;
  if (item.term && item.term.id) return item.term.id;
  if (item.note) return item.note;
  if (item.url) return item.url;
  if (item.edtf) return item.edtf;
  if (item.id) return item.id;
  return null;
}

/**
 * Human-readable label for a single provenance value item. Prefers a
 * controlled-term label (with role), then common label-ish fields, falling
 * back to JSON so the value is never silently hidden.
 */
function provenanceItemLabel(item) {
  if (item == null) return "—";
  if (typeof item !== "object") return String(item);
  if (item.term) {
    const base = item.term.label || item.term.id || "—";
    return item.role && item.role.label ? `${base} (${item.role.label})` : base;
  }
  // related_url: { url, label: { id, label, scheme } } — the entry's `label`
  // is a coded-term object, so render its `.label` string, never the object.
  if (item.url) {
    const labelText = codedLabelText(item.label);
    return labelText ? `${labelText}: ${item.url}` : item.url;
  }
  // notes: { note, type: { id, label, scheme } }
  if (item.note) {
    const typeLabel = codedLabelText(item.type);
    return typeLabel ? `${typeLabel}: ${item.note}` : item.note;
  }
  return (
    codedLabelText(item.label) ||
    item.humanized ||
    item.edtf ||
    item.id ||
    JSON.stringify(item, null, 0)
  );
}

/**
 * A coded-term `label` may arrive as a resolved `{ id, label, scheme }` object
 * or as a bare string. Return a renderable string in either case (never an
 * object, which React refuses to render as a child).
 */
function codedLabelText(label) {
  if (label == null) return "";
  if (typeof label === "string") return label;
  return label.label || label.id || "";
}

/**
 * Render the actual value a provenance target/event touched, so reviewers can
 * see *what* changed (e.g. which subject terms were AI generated) rather than
 * just the field path. Multivalued fields render as a list and, when per-item
 * provenance is supplied, each item is badged with its own origin — mirroring
 * the plan diff view. Renders nothing for empty/missing values.
 */
export function ProvenanceValue({ value, itemProvenance = [] }) {
  const unwrapped = unwrapProvenanceValue(value);
  if (unwrapped == null || unwrapped === "") return null;

  const originById = (itemProvenance || []).reduce((acc, entry) => {
    if (entry?.id) acc[entry.id] = entry.origin;
    return acc;
  }, {});

  if (Array.isArray(unwrapped)) {
    if (unwrapped.length === 0) return null;
    return (
      <ul className="provenance-value" data-testid="provenance-value">
        {unwrapped.map((item, i) => {
          const id = provenanceItemId(item);
          const origin = id ? originById[id] : undefined;
          return (
            <li key={id || i} className="is-size-7">
              {provenanceItemLabel(item)}
              {origin && (
                <span className="ml-2">
                  <OriginBadge origin={origin} />
                </span>
              )}
            </li>
          );
        })}
      </ul>
    );
  }

  return (
    <span className="is-size-7" data-testid="provenance-value">
      {provenanceItemLabel(unwrapped)}
    </span>
  );
}

ProvenanceValue.propTypes = {
  value: PropTypes.any,
  itemProvenance: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string,
      origin: PropTypes.string,
    }),
  ),
};

function formatEventDate(value) {
  if (!value) return "—";
  return new Date(value).toLocaleString();
}

/**
 * Render a single stored event value (before/after snapshot) on one labeled
 * line. Values persist wrapped as `{ value: ... }`; arrays are joined and
 * scalars rendered via the shared item-label helper. Renders nothing when the
 * value is empty so unchanged/missing snapshots stay out of the way.
 */
function ProvenanceEventValue({ label, value }) {
  const unwrapped = unwrapProvenanceValue(value);
  if (!hasValue(unwrapped)) return null;
  const text = Array.isArray(unwrapped)
    ? unwrapped.map(provenanceItemLabel).join(", ")
    : provenanceItemLabel(unwrapped);
  return (
    <div className="is-size-7">
      <span className="has-text-grey">{label}:</span> {text}
    </div>
  );
}

ProvenanceEventValue.propTypes = {
  label: PropTypes.string,
  value: PropTypes.any,
};

/**
 * Show the value transition an event captured — the AI/original value it
 * replaced ("From") and the value it set ("To") — so reviewers can read the
 * original AI text alongside a human edit directly in the timeline. Renders
 * nothing when neither snapshot is present.
 */
export function ProvenanceEventValues({ valueBefore, valueAfter }) {
  const before = unwrapProvenanceValue(valueBefore);
  const after = unwrapProvenanceValue(valueAfter);
  if (!hasValue(before) && !hasValue(after)) return null;
  // A human attestation can record an unchanged value (the human asserts
  // responsibility for the same value the AI proposed). Call that out rather
  // than showing an identical From/To pair that looks like a no-op edit.
  if (hasValue(before) && JSON.stringify(before) === JSON.stringify(after)) {
    return (
      <div className="mt-1" data-testid="provenance-event-values">
        <div className="is-size-7 has-text-grey">
          Value unchanged; human attested responsibility for the live value.
        </div>
      </div>
    );
  }
  return (
    <div className="mt-1" data-testid="provenance-event-values">
      <ProvenanceEventValue label="From" value={valueBefore} />
      <ProvenanceEventValue label="To" value={valueAfter} />
    </div>
  );
}

ProvenanceEventValues.propTypes = {
  valueBefore: PropTypes.any,
  valueAfter: PropTypes.any,
};

/**
 * Compact, readable timeline for a target's provenance events. Lays each event
 * out vertically — event type (with outcome) on the first line, actor and
 * timestamp muted below, then any notes and signing agents — so the column
 * stays legible even when narrow. Renders nothing when there are no events.
 */
export function ProvenanceEvents({ events = [] }) {
  if (!events || events.length === 0) return null;
  return (
    <ul className="provenance-events" data-testid="provenance-events">
      {events.map((event) => (
        <li key={event.id} className="mb-2">
          <div>
            <span className="tag is-light is-small mr-1">
              {event.eventType}
            </span>
            {event.outcome && (
              <span className="is-size-7 has-text-grey">{event.outcome}</span>
            )}
          </div>
          <div
            className="is-size-7 has-text-grey"
            style={{ whiteSpace: "nowrap" }}
          >
            {event.actor ? `${event.actor} · ` : ""}
            {formatEventDate(event.occurredAt)}
          </div>
          {event.itemIdentifier && (
            <div className="is-size-7 has-text-grey" data-testid="event-item">
              Item: {event.itemIdentifier}
            </div>
          )}
          <ProvenanceEventValues
            valueBefore={event.valueBefore}
            valueAfter={event.valueAfter}
          />
          {event.notes && <div className="is-size-7">{event.notes}</div>}
          {(event.agentLinks || []).map((link) => (
            <span key={link.id} className="tag is-white is-small mt-1">
              {link.role}: {link.agent?.name}
            </span>
          ))}
        </li>
      ))}
    </ul>
  );
}

ProvenanceEvents.propTypes = {
  events: PropTypes.array,
};

function toSnakeCase(value) {
  return value.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`);
}

/**
 * Look up the provenance entry for a metadata field by its frontend (camelCase)
 * name. Provenance field paths are snake_case backend field names
 * (e.g. `descriptive_metadata.style_period`), so we try both spellings.
 */
export function fieldProvenance(
  provenance,
  name,
  section = "descriptive_metadata",
) {
  if (!provenance) return undefined;
  return (
    provenance[`${section}.${name}`] ||
    provenance[`${section}.${toSnakeCase(name)}`]
  );
}

/**
 * Build a lookup of provenance summary entries keyed by their field_path,
 * so callers (e.g. the About tab) can find provenance for a given field.
 * When more than one entry shares a field_path, the most recent wins.
 */
export function provenanceByFieldPath(summary = []) {
  return summary.reduce((acc, entry) => {
    const existing = acc[entry.fieldPath];
    if (!existing || entryIsNewer(entry, existing)) {
      acc[entry.fieldPath] = entry;
    }
    return acc;
  }, {});
}

function entryIsNewer(a, b) {
  const aTime = a.appliedAt || a.reviewedAt || a.generatedAt || "";
  const bTime = b.appliedAt || b.reviewedAt || b.generatedAt || "";
  return aTime > bTime;
}

/**
 * Compose a human-readable tooltip describing an origin/reviewer/date for a
 * provenance entry, used on inline badges.
 */
export function provenanceTooltip(entry) {
  if (!entry) return "";
  const meta = ORIGIN_META[entry.origin];
  const parts = [meta ? meta.label : humanize(entry.origin)];
  if (entry.origin === "human_attested_after_ai") {
    parts.push(
      "A human asserted responsibility for this value after prior AI provenance. " +
        "The AI history is retained in the Provenance tab.",
    );
  }
  if (entry.model) parts.push(`model ${entry.model}`);
  if (entry.reviewer) {
    const when = entry.reviewedAt
      ? new Date(entry.reviewedAt).toLocaleDateString()
      : null;
    parts.push(
      when
        ? `reviewed by ${entry.reviewer} on ${when}`
        : `reviewed by ${entry.reviewer}`,
    );
  }
  return parts.join(" · ");
}
