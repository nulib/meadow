import React from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/client/react";
import { ATTEST_HUMAN_AUTHORED_METADATA, GET_WORK } from "../Work/work.gql";
import { isItemAttestable } from "./Attestation";
import { useAIProvenanceBadges } from "@js/context/ai-provenance-context";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { IconUserCheck } from "@js/components/Icon";
import { toastWrapper } from "@js/services/helpers";

/**
 * Per-item "mark human-authored" control rendered in display mode next to an AI
 * item's origin badge (a subject term, a description, …). Lets a cataloger
 * attest a single item of a multivalued field as human-authored without editing
 * the value, mirroring the scalar `HumanAuthoredFieldControl` but at item
 * granularity. Fires `attestHumanAuthoredMetadata` with one field path + one
 * item id and refetches the work so the item's badge flips to "Human attested".
 *
 * Renders nothing unless provenance badges are visible, the item's origin is
 * still attestable (AI-involved, not already attested), and the viewer is an
 * Editor. The AI history is preserved — this records an attestation event, it
 * does not erase prior provenance.
 */
function ItemAttestationControl({ workId, fieldPath, itemId }) {
  const { visible } = useAIProvenanceBadges();
  const [open, setOpen] = React.useState(false);
  const [reason, setReason] = React.useState("");

  const [attest, { loading }] = useMutation(ATTEST_HUMAN_AUTHORED_METADATA, {
    refetchQueries: [{ query: GET_WORK, variables: { id: workId } }],
    awaitRefetchQueries: true,
    onCompleted() {
      toastWrapper("is-success", "Item marked as human-authored");
      setOpen(false);
      setReason("");
    },
    onError(error) {
      toastWrapper(
        "is-danger",
        `Could not mark item human-authored: ${error.message}`,
      );
    },
  });

  if (!visible || !workId || !fieldPath || !itemId) return null;

  const handleConfirm = () => {
    attest({
      variables: {
        workId,
        fieldPaths: [fieldPath],
        itemIds: [itemId],
        ...(reason ? { reason } : {}),
      },
    });
  };

  return (
    <AuthDisplayAuthorized level="EDITOR">
      <span className="ml-2 is-inline-block" data-testid="item-attestation">
        {open ? (
          <span className="field has-addons is-inline-flex">
            <span className="control">
              <input
                className="input is-small"
                type="text"
                placeholder="Reason (optional)"
                data-testid="item-attestation-reason"
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
                data-testid="item-attestation-confirm"
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
                data-testid="item-attestation-cancel"
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
            data-testid="item-attestation-trigger"
            title="Mark this item as human-authored (preserves AI history)"
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

ItemAttestationControl.propTypes = {
  workId: PropTypes.string,
  fieldPath: PropTypes.string,
  itemId: PropTypes.string,
};

/**
 * Convenience wrapper: render the control only when the item's per-item origin
 * is attestable. Keeps the attestable rule out of the display components.
 */
export function ItemAttestation({ origin, ...props }) {
  if (!isItemAttestable(origin)) return null;
  return <ItemAttestationControl {...props} />;
}

ItemAttestation.propTypes = {
  origin: PropTypes.string,
  workId: PropTypes.string,
  fieldPath: PropTypes.string,
  itemId: PropTypes.string,
};

export default ItemAttestationControl;
