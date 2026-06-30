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
 */
function AnnotationAttestationControl({ annotation, workId }) {
  const { visible } = useAIProvenanceBadges();
  const [open, setOpen] = React.useState(false);
  const [reason, setReason] = React.useState("");

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

  const handleConfirm = () => {
    attest({
      variables: {
        annotationId,
        ...(reason ? { reason } : {}),
      },
    });
  };

  return (
    <AuthDisplayAuthorized level="EDITOR">
      <span data-testid="annotation-attestation">
        {open ? (
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
                  loading ? "is-loading" : ""
                }`}
                data-testid="annotation-attestation-confirm"
                disabled={loading}
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
                disabled={loading}
                onClick={() => setOpen(false)}
              >
                Cancel
              </button>
            </span>
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
};

export default AnnotationAttestationControl;
