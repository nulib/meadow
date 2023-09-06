import React, { useState } from "react";
import PropTypes from "prop-types";
import { useHistory } from "react-router-dom";
import { Button, Notification } from "@nulib/design-system";
import { TRANSFER_FILE_SETS } from "@js/components/Work/work.gql.js";
import { useMutation } from "@apollo/client";
import { toastWrapper } from "@js/services/helpers";
import { useForm, FormProvider } from "react-hook-form";
import Error from "@js/components/UI/Error";
import classNames from "classnames";
import UIFormField from "@js/components/UI/Form/Field.jsx";
import UIInput from "@js/components/UI/Form/Input";
import { css } from "@emotion/react";

const modalCss = css`
  z-index: 100;
`;

function WorkTabsPreservationTransferFileSetsModal({
  closeModal,
  isVisible,
  fromWorkId,
}) {
  const defaultValues = {
    fromWorkId: null,
  };

  const [formError, setFormError] = useState();
  const [confirmationInput, setConfirmationInput] = useState("");
  const [confirmationError, setConfirmationError] = useState();
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [toWorkId, setToWorkId] = useState("");

  const methods = useForm({
    defaultValues: defaultValues,
    shouldUnregister: false,
  });

  const history = useHistory();

  const handleToWorkIdChange = (e) => {
    setToWorkId(e.target.value);
  };

  const [transferFileSets, { loading, error, data }] = useMutation(
    TRANSFER_FILE_SETS,
    {
      onCompleted({ transferFileSets }) {
        toastWrapper(
          "is-success",
          `FileSets transferred successfully to work: ${transferFileSets.id}`
        );
        resetForm();
        history.push(`/work/${transferFileSets.id}`);
      },
      onError(error) {
        console.error(
          "error in the transferFileSets GraphQL mutation :>> ",
          error
        );
        console.error("error MESSAGE", error.message)
        console.error("graphQL ERRORS", error.graphQLErrors)
        setFormError(error);
      },
    }
  );

  const handleSubmit = (data) => {
    setToWorkId(data.toWorkId);
    setIsSubmitted(true);
    if (confirmationInput !== "I understand") {
      setConfirmationError({
        confirmationText: "Confirmation text is required.",
      });
      return;
    }
    setConfirmationError(null);

    transferFileSets({
      variables: {
        fromWorkId: fromWorkId,
        toWorkId: data.toWorkId,
      },
    });
  };

  const handleCancel = () => {
    resetForm();
    closeModal();
  };

  const resetForm = () => {
    methods.reset();
  };

  const handleConfirmationChange = (e) => {
    const value = e.target.value;
    setConfirmationInput(value);
    setConfirmationError(null);
  };

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
              <p className="modal-card-title">
                Transfer FileSets between Works
              </p>
              <button
                type="button"
                className="delete"
                aria-label="close"
                onClick={handleCancel}
              ></button>
            </header>

            <section className="modal-card-body">
              {error && <Error error={error} />}
              <strong>From Work ID:</strong> {fromWorkId}
              <UIFormField label="To Work ID:">
                <UIInput
                  isReactHookForm
                  onChange={handleToWorkIdChange}
                  name="toWorkId"
                  label="To Work ID:"
                  data-testid="toWorkId"
                />
              </UIFormField>
              <Notification isCentered className="content">
                <div className="block">
                  <strong>To execute this transfer, type "I understand"</strong>
                </div>
                <div>
                  <UIInput
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
                disabled={
                  loading ||
                  toWorkId === "" ||
                  confirmationInput !== "I understand"
                }
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
};

export default WorkTabsPreservationTransferFileSetsModal;
