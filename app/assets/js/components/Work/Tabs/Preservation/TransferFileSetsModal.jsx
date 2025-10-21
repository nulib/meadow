/** @jsx jsx */
import React, { useState } from "react";
import PropTypes from "prop-types";
import { useHistory } from "react-router-dom";
import { Button, Notification } from "@nulib/design-system";
import { TRANSFER_FILE_SETS_SUBSET } from "@js/components/Work/work.gql.js";
import { useMutation } from "@apollo/client";
import { toastWrapper } from "@js/services/helpers";
import { useForm, FormProvider } from "react-hook-form";
import Error from "@js/components/UI/Error";
import classNames from "classnames";
import UIFormField from "@js/components/UI/Form/Field.jsx";
import UIFormInput from "@js/components/UI/Form/Input";
import { css, jsx } from "@emotion/react";

const modalCss = css`
  z-index: 100;
`;

const summaryBox = css`
  background-color: #f5f5f5;
  margin-bottom: 1rem;
`;

const previewBox = css`
  margin-bottom: 1rem;
`;

const previewList = css`
  max-height: 300px;
  overflow-y: auto;
`;

const previewItem = css`
  display: flex;
  gap: 1rem;
  margin-bottom: 0.75rem;
  padding: 0.5rem;
  background-color: #fafafa;
  border-radius: 4px;
`;

const previewFigure = css`
  width: 60px;
  height: 60px;
  flex-shrink: 0;

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 4px;
  }
`;

const previewContent = css`
  flex: 1;
  min-width: 0;
`;

const previewFilename = css`
  font-size: 0.875rem;
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
`;

const previewRole = css`
  font-size: 0.75rem;
  color: #666;
`;

const radioLabel = css`
  margin-left: 8px;
`;

function WorkTabsPreservationTransferFileSetsModal({
  closeModal,
  isVisible,
  fromWorkId,
  selectedFilesets,
  work,
}) {
  const defaultValues = {
    transferDestination: "existing",
    accessionNumber: "",
    newWorkAccessionNumber: "",
    newWorkTitle: "",
  };

  const [confirmationInput, setConfirmationInput] = useState("");
  const [confirmationError, setConfirmationError] = useState();
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [transferDestination, setTransferDestination] = useState("existing");
  const [showPreview, setShowPreview] = useState(false);

  const methods = useForm({
    defaultValues: defaultValues,
    shouldUnregister: false,
  });

  const history = useHistory();

  const [transferFileSetsSubset, { loading, error, data, reset: resetMutation }] = useMutation(
    TRANSFER_FILE_SETS_SUBSET,
    {
      onCompleted({ transferFileSetsSubset }) {
        const { transferredFilesetIds, createdWorkId } = transferFileSetsSubset;
        const targetWorkId =
          createdWorkId || methods.getValues("accessionNumber");

        toastWrapper(
          "is-success",
          `${transferredFilesetIds.length} fileset(s) transferred successfully${
            createdWorkId ? " to new work" : ""
          }`,
        );
        resetForm();

        // Navigate to the target work (either created or existing)
        if (createdWorkId) {
          history.push(`/work/${createdWorkId}`);
        } else {
          // For existing work, close the modal and let the user navigate manually
          closeModal();
        }
      },
      onError(error) {
        console.error(
          "error in the transferFileSetsSubset GraphQL mutation :>> ",
          error,
        );
      },
    },
  );

  const handleSubmit = (data) => {
    setIsSubmitted(true);
    if (confirmationInput !== "I understand") {
      setConfirmationError({
        confirmationText: "Confirmation text is required.",
      });
      return;
    }
    setConfirmationError(null);

    const isCreatingNewWork = transferDestination === "new";

    if (isCreatingNewWork) {
      // Create new work
      transferFileSetsSubset({
        variables: {
          filesetIds: selectedFilesets,
          createWork: true,
          workAttributes: {
            accessionNumber: data.newWorkAccessionNumber,
            workType: work.workType.id,
            descriptiveMetadata: {
              title: data.newWorkTitle,
            },
          },
          deleteEmptyWorks: true,
        },
      });
    } else {
      // Transfer to existing work
      transferFileSetsSubset({
        variables: {
          filesetIds: selectedFilesets,
          createWork: false,
          accessionNumber: data.accessionNumber,
          deleteEmptyWorks: true,
        },
      });
    }
  };

  const handleCancel = () => {
    resetForm();
    closeModal();
  };

  const resetForm = () => {
    methods.reset();
    setConfirmationInput("");
    setTransferDestination("existing");
    setShowPreview(false);
    setIsSubmitted(false);
    setConfirmationError(null);
  };

  // Clear error and reset form when modal opens
  React.useEffect(() => {
    if (!isVisible) {
      // Modal is closing, keep state for next open
      return;
    }
    // Modal is opening, reset form state and clear any GraphQL errors
    resetForm();
    if (resetMutation) {
      resetMutation();
    }
  }, [isVisible, resetMutation]);

  const handleConfirmationChange = (e) => {
    const value = e.target.value;
    setConfirmationInput(value);
    setConfirmationError(null);
  };

  const selectedFilesetsData = work.fileSets.filter((fs) =>
    selectedFilesets.includes(fs.id),
  );

  const remainingFilesetsCount = work.fileSets.length - selectedFilesets.length;

  return (
    <div
      className={classNames("modal", {
        "is-active": isVisible,
      })}
      css={modalCss}
    >
      <div className="modal-background"></div>
      <FormProvider {...methods}>
        <form
          onSubmit={methods.handleSubmit(handleSubmit)}
          data-testid="transfer-filesets-form"
        >
          <div className="modal-card">
            <header className="modal-card-head">
              <p className="modal-card-title">Transfer FileSets</p>
              <button
                type="button"
                className="delete"
                aria-label="close"
                onClick={handleCancel}
              ></button>
            </header>

            <section className="modal-card-body">
              {error && <Error error={error} />}

              {/* Transfer Summary */}
              <div className="box" css={summaryBox}>
                <p className="mb-2">
                  <strong>
                    Transferring {selectedFilesets.length} fileset(s)
                  </strong>
                  {remainingFilesetsCount > 0 &&
                    ` (${remainingFilesetsCount} will remain in current work)`}
                </p>
                <p className="mb-2">
                  <strong>From Work:</strong> {work.accessionNumber}
                  {work.descriptiveMetadata?.title &&
                    ` - ${work.descriptiveMetadata.title}`}
                </p>
                <p>
                  <strong>Work Type:</strong>{" "}
                  {work.workType?.label || work.workType?.id}
                </p>
              </div>

              <div className="field mt-4">
                <label className="checkbox">
                  <input
                    type="checkbox"
                    checked={showPreview}
                    onChange={(e) => setShowPreview(e.target.checked)}
                  />
                  <span css={radioLabel}>
                    Show preview of selected filesets
                  </span>
                </label>
              </div>

              {/* Preview Section */}
              {showPreview && (
                <div className="box" css={previewBox}>
                  <p className="has-text-weight-bold mb-2">
                    Selected Filesets:
                  </p>
                  <div css={previewList}>
                    {selectedFilesetsData.map((fs) => (
                      <div key={fs.id} css={previewItem}>
                        {fs.representativeImageUrl && (
                          <figure css={previewFigure}>
                            <img
                              src={`${fs.representativeImageUrl}/square/60,/0/default.jpg`}
                              alt={
                                fs.coreMetadata?.originalFilename || "Fileset"
                              }
                              onError={(e) => {
                                e.target.src = "/images/placeholder.png";
                              }}
                            />
                          </figure>
                        )}
                        <div css={previewContent}>
                          <p css={previewFilename}>
                            {fs.coreMetadata?.originalFilename || fs.id}
                          </p>
                          <p css={previewRole}>
                            Role: {fs.role?.id || "N/A"}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <div className="field">
                <label className="label">Transfer Destination</label>
                <div className="control">
                  <label className="radio">
                    <input
                      type="radio"
                      name="transferDestination"
                      value="existing"
                      checked={transferDestination === "existing"}
                      onChange={(e) => setTransferDestination(e.target.value)}
                    />
                    <span css={radioLabel}>
                      Transfer to existing work
                    </span>
                  </label>
                </div>
                <div className="control">
                  <label className="radio">
                    <input
                      type="radio"
                      name="transferDestination"
                      value="new"
                      checked={transferDestination === "new"}
                      onChange={(e) => setTransferDestination(e.target.value)}
                    />
                    <span css={radioLabel}>Create new work</span>
                  </label>
                </div>
              </div>

              {transferDestination === "existing" ? (
                <UIFormField label="Target Work Accession Number">
                  <UIFormInput
                    isReactHookForm
                    name="accessionNumber"
                    label="Target Work Accession Number"
                    placeholder="Enter accession number"
                    required
                    data-testid="accession-number"
                  />
                  <p className="help">
                    Enter the accession number of the work to transfer filesets
                    to. The work must be of type:{" "}
                    {work.workType?.label || work.workType?.id}
                  </p>
                </UIFormField>
              ) : (
                <>
                  <UIFormField label="New Work Accession Number">
                    <UIFormInput
                      isReactHookForm
                      name="newWorkAccessionNumber"
                      label="New Work Accession Number"
                      placeholder="Enter new work accession number"
                      required
                      data-testid="new-work-accession-number"
                    />
                  </UIFormField>
                  <UIFormField label="New Work Title">
                    <UIFormInput
                      isReactHookForm
                      name="newWorkTitle"
                      label="New Work Title"
                      placeholder="Enter new work title"
                      data-testid="new-work-title"
                    />
                  </UIFormField>
                  <Notification>
                    <p>
                      New work will be created with work type:{" "}
                      <strong>
                        {work.workType?.label || work.workType?.id}
                      </strong>
                    </p>
                  </Notification>
                </>
              )}

              <Notification isCentered className="content mt-4">
                <div className="block">
                  <strong>To execute this transfer, type "I understand"</strong>
                </div>
                <div>
                  <UIFormInput
                    isReactHookForm
                    onChange={handleConfirmationChange}
                    name="confirmationText"
                    label="Confirmation Text"
                    placeholder="I understand"
                    required
                    data-testid="confirmation-text"
                  />
                  {isSubmitted && confirmationError && (
                    <p className="help is-danger">
                      {confirmationError.confirmationText}
                    </p>
                  )}
                </div>
              </Notification>
            </section>

            <footer className="modal-card-foot is-justify-content-flex-end">
              <Button
                isText
                type="button"
                onClick={handleCancel}
                data-testid="cancel-button"
              >
                Cancel
              </Button>
              <Button
                isPrimary
                type="submit"
                disabled={loading || confirmationInput !== "I understand"}
                data-testid="submit-button"
              >
                Transfer FileSets
              </Button>
            </footer>
          </div>
        </form>
      </FormProvider>
    </div>
  );
}

WorkTabsPreservationTransferFileSetsModal.propTypes = {
  closeModal: PropTypes.func,
  isVisible: PropTypes.bool,
  fromWorkId: PropTypes.string.isRequired,
  selectedFilesets: PropTypes.arrayOf(PropTypes.string).isRequired,
  work: PropTypes.object.isRequired,
};

export default WorkTabsPreservationTransferFileSetsModal;
