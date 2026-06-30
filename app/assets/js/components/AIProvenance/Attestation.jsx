import React from "react";
import PropTypes from "prop-types";
import { useWatch, useFormContext } from "react-hook-form";

/**
 * Explicit "mark current value as human-authored" affordance for fields that
 * carry AI provenance. This does NOT erase the AI history — on save it records
 * a human attestation event (see `record_work_human_attestation` on the
 * backend), preserving the prior AI target/events while declaring the live
 * value human-owned.
 *
 * State lives in a context so the per-field controls (rendered deep in the
 * metadata field components) and the form submit handler (in the About tab) can
 * share it without prop drilling.
 */

const AttestationContext = React.createContext({
  attestations: {},
  setAttestation: () => {},
  clearAttestation: () => {},
  attestationsInput: () => [],
});

function AttestationProvider({ children }) {
  // Map of field_path -> { reason }. Presence of a key means "attest this field".
  const [attestations, setAttestations] = React.useState({});

  const setAttestation = React.useCallback((fieldPath, reason = null) => {
    setAttestations((prev) => ({ ...prev, [fieldPath]: { reason } }));
  }, []);

  const clearAttestation = React.useCallback((fieldPath) => {
    setAttestations((prev) => {
      const next = { ...prev };
      delete next[fieldPath];
      return next;
    });
  }, []);

  // Shape the attestation state for the `humanAuthoredAttestations` mutation
  // input. Returns undefined when empty so the variable is simply omitted.
  const attestationsInput = React.useCallback(() => {
    const entries = Object.entries(attestations);
    if (entries.length === 0) return undefined;
    return entries.map(([fieldPath, { reason }]) => ({
      fieldPath,
      ...(reason ? { reason } : {}),
    }));
  }, [attestations]);

  const value = React.useMemo(
    () => ({
      attestations,
      setAttestation,
      clearAttestation,
      attestationsInput,
    }),
    [attestations, setAttestation, clearAttestation, attestationsInput],
  );

  return (
    <AttestationContext.Provider value={value}>
      {children}
    </AttestationContext.Provider>
  );
}

AttestationProvider.propTypes = {
  children: PropTypes.node,
};

function useAttestation() {
  return React.useContext(AttestationContext);
}

// Origins where a human can still meaningfully attest the live value: AI was
// involved and the field has not already been attested or cleared.
const ATTESTABLE_ORIGINS = [
  "ai_generated",
  "ai_modified_human_content",
  "ai_assisted_human_modified",
  "human_replacement_after_ai_suggestion",
];
const INACTIVE_STATUSES = ["deleted", "rejected", "failed"];

export function isAttestable(entry) {
  if (!entry) return false;
  if (INACTIVE_STATUSES.includes(entry.status)) return false;
  return ATTESTABLE_ORIGINS.includes(entry.origin);
}

/**
 * Whether a single item of a multivalued field (given its per-item origin) can
 * still be meaningfully attested as human-authored: AI was involved and it has
 * not already been attested. Single-sources the attestable rule with the
 * field-level `isAttestable`, used by the per-item display control.
 */
export function isItemAttestable(origin) {
  return ATTESTABLE_ORIGINS.includes(origin);
}

/**
 * Confirmation shown when a user attests a value that has NOT been changed from
 * the AI-provenanced value. We don't block — legitimate human attestation of an
 * identical value is allowed — but we confirm to prevent accidental "badge
 * laundering" of AI content as human-authored.
 */
function SameValueConfirm({ isOpen, reason, onReason, onCancel, onConfirm }) {
  if (!isOpen) return null;
  return (
    <div className="modal is-active" data-testid="attestation-same-value-modal">
      <div className="modal-background" onClick={onCancel}></div>
      <div className="modal-content">
        <div className="box">
          <p className="mb-3">
            This value is the same as the AI-generated value. Marking it
            human-authored will not erase the AI history; it will record that
            you are taking responsibility for the current value. Continue?
          </p>
          <div className="field">
            <label className="label is-small">Reason or note (optional)</label>
            <input
              className="input"
              type="text"
              data-testid="attestation-reason"
              value={reason || ""}
              onChange={(e) => onReason(e.target.value)}
            />
          </div>
          <div className="buttons is-right">
            <button
              type="button"
              className="button is-text"
              data-testid="attestation-cancel"
              onClick={onCancel}
            >
              Cancel
            </button>
            <button
              type="button"
              className="button is-primary"
              data-testid="attestation-confirm"
              onClick={onConfirm}
            >
              Mark human-authored
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

SameValueConfirm.propTypes = {
  isOpen: PropTypes.bool,
  reason: PropTypes.string,
  onReason: PropTypes.func,
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
};

/**
 * Per-field control rendered in edit mode for an AI-provenanced field. Lets the
 * cataloger declare the current value human-authored. When the current form
 * value is unchanged from the AI value, a confirmation modal appears first;
 * when the value has been edited, the checkbox marks it directly (lower
 * friction). An optional reason can be supplied either way.
 *
 * `name` is the React Hook Form field name to watch for the current value, and
 * `originalValue` is the value the work loaded with, used only to decide whether
 * to confirm. The same/different decision is never used to choose the backend
 * event type — that is always an explicit attestation.
 */
export function HumanAuthoredFieldControl({ entry, name, originalValue }) {
  const { control } = useFormContext();
  const watched = useWatch({ control, name });
  const { attestations, setAttestation, clearAttestation } = useAttestation();

  const [confirmOpen, setConfirmOpen] = React.useState(false);
  const [reason, setReason] = React.useState("");

  if (!isAttestable(entry)) return null;

  const fieldPath = entry.fieldPath;
  const checked = Boolean(attestations[fieldPath]);
  const currentValue = watched === undefined ? originalValue : watched;
  const unchanged = String(currentValue ?? "") === String(originalValue ?? "");

  const handleToggle = (e) => {
    if (!e.target.checked) {
      clearAttestation(fieldPath);
      return;
    }
    if (unchanged) {
      setConfirmOpen(true);
    } else {
      setAttestation(fieldPath, reason || null);
    }
  };

  const handleConfirm = () => {
    setAttestation(fieldPath, reason || null);
    setConfirmOpen(false);
  };

  return (
    <div className="mt-1" data-testid="human-authored-control">
      <label className="checkbox is-size-7">
        <input
          type="checkbox"
          className="mr-1"
          data-testid="human-authored-checkbox"
          checked={checked}
          onChange={handleToggle}
        />
        Mark current value as human-authored
      </label>
      <p className="help">
        This will not erase the AI provenance history. It will record that you
        are taking responsibility for the current value as human-authored
        metadata.
      </p>
      {checked && !unchanged && (
        <div className="field">
          <input
            className="input is-small"
            type="text"
            placeholder="Reason or note (optional)"
            data-testid="attestation-reason-inline"
            value={reason}
            onChange={(e) => {
              setReason(e.target.value);
              setAttestation(fieldPath, e.target.value || null);
            }}
          />
        </div>
      )}
      <SameValueConfirm
        isOpen={confirmOpen}
        reason={reason}
        onReason={setReason}
        onCancel={() => setConfirmOpen(false)}
        onConfirm={handleConfirm}
      />
    </div>
  );
}

HumanAuthoredFieldControl.propTypes = {
  entry: PropTypes.object,
  name: PropTypes.string,
  originalValue: PropTypes.any,
};

export { AttestationContext, AttestationProvider, useAttestation };
