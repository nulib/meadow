import React from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/client/react";
import { ATTEST_HUMAN_AUTHORED_ANNOTATION } from "@js/components/Work/Tabs/Structure/Transcription/transcription.gql";
import { GET_WORK } from "@js/components/Work/work.gql";
import { isAttestable } from "./Attestation";
import { useAIProvenanceBadges } from "@js/context/ai-provenance-context";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { IconUserCheck } from "@js/components/Icon";
import { toastWrapper } from "@js/services/helpers";

/**
 * "Mark human-authored" control for an AI-generated file set annotation (e.g. a
 * transcription), shown next to its origin badge. The annotation counterpart of
 * the work field's `HumanAuthoredFieldControl`: it records an attestation event
 * declaring the live content human-owned without erasing the AI history, and
 * does not change the content. Fires `attestHumanAuthoredAnnotation` and
 * refetches the work so the badge flips to "Human attested".
 *
 * Renders nothing unless provenance badges are visible, the annotation's AI
 * provenance is still attestable (AI-involved, not already attested), and the
 * viewer is an Editor.
 *
 * When the surrounding editor reports unsaved changes (`hasUnsavedChanges`),
 * confirming first awaits `onBeforeAttest` so those edits are saved before the
 * attestation is recorded; a note below the controls tells the reviewer this
 * will happen. A failed save aborts the attestation.
 */
function AnnotationAttestationControl({
  annotation,
  workId,
  hasUnsavedChanges,
  onBeforeAttest,
}) {
  const { visible } = useAIProvenanceBadges();
  const [open, setOpen] = React.useState(false);
  const [reason, setReason] = React.useState("");
  const [saving, setSaving] = React.useState(false);

  const [attest, { loading }] = useMutation(ATTEST_HUMAN_AUTHORED_ANNOTATION, {
    refetchQueries: workId
      ? [{ query: GET_WORK, variables: { id: workId } }]
      : [],
    awaitRefetchQueries: true,
    onCompleted() {
      toastWrapper("is-success", "Transcription marked as human-authored");
      setOpen(false);
      setReason("");
    },
    onError(error) {
      toastWrapper(
        "is-danger",
        `Could not mark transcription human-authored: ${error.message}`,
      );
    },
  });

  const annotationId = annotation?.id;
  if (!visible || !annotationId) return null;
  if (!isAttestable(annotation.aiProvenance)) return null;

  const busy = loading || saving;

  const handleConfirm = async () => {
    if (hasUnsavedChanges && onBeforeAttest) {
      setSaving(true);
      try {
        await onBeforeAttest();
      } catch (error) {
        toastWrapper(
          "is-danger",
          `Could not save transcription edits: ${error.message}`,
        );
        return;
      } finally {
        setSaving(false);
      }
    }
    attest({
      variables: {
        annotationId,
        ...(reason ? { reason } : {}),
      },
    });
  };

  return (
    <AuthDisplayAuthorized level="EDITOR">
      {/* When open, take a full row of the wrapping header so the input,
          buttons, and autosave note sit on their own lines instead of
          crowding the badge and the controls below. */}
      <span
        data-testid="annotation-attestation"
        style={open ? { flexBasis: "100%" } : undefined}
      >
        {open ? (
          <span className="is-block">
            <span className="field has-addons is-inline-flex mb-0">
              <span className="control">
                <input
                  className="input is-small"
                  type="text"
                  placeholder="Reason (optional)"
                  data-testid="annotation-attestation-reason"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                />
              </span>
              <span className="control">
                <button
                  type="button"
                  className={`button is-small is-primary ${
                    busy ? "is-loading" : ""
                  }`}
                  data-testid="annotation-attestation-confirm"
                  disabled={busy}
                  onClick={handleConfirm}
                >
                  Mark human-authored
                </button>
              </span>
              <span className="control">
                <button
                  type="button"
                  className="button is-small"
                  data-testid="annotation-attestation-cancel"
                  disabled={busy}
                  onClick={() => setOpen(false)}
                >
                  Cancel
                </button>
              </span>
            </span>
            {hasUnsavedChanges && (
              <span
                className="help is-block has-text-grey mt-1 mb-0"
                data-testid="annotation-attestation-autosave-note"
              >
                Your unsaved edits will be saved automatically.
              </span>
            )}
          </span>
        ) : (
          <button
            type="button"
            className="button is-small is-ghost px-2 has-text-grey"
            data-testid="annotation-attestation-trigger"
            title="Mark this transcription as human-authored (preserves AI history)"
            aria-label="Mark human-authored"
            onClick={() => setOpen(true)}
          >
            <IconUserCheck />
          </button>
        )}
      </span>
    </AuthDisplayAuthorized>
  );
}

AnnotationAttestationControl.propTypes = {
  annotation: PropTypes.shape({
    id: PropTypes.string,
    aiProvenance: PropTypes.shape({
      origin: PropTypes.string,
      status: PropTypes.string,
    }),
  }),
  workId: PropTypes.string,
  hasUnsavedChanges: PropTypes.bool,
  onBeforeAttest: PropTypes.func,
};

export default AnnotationAttestationControl;
