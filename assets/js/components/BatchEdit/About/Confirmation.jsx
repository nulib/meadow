import React, { useState } from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import UIFormInput from "../../UI/Form/Input";
import { toastWrapper } from "../../../services/helpers";
import { BATCH_UPDATE } from "../batch-edit.gql";
import { useMutation } from "@apollo/client";
import BatchEditConfirmationTable from "./ConfirmationTable";
import { removeLabelsFromBatchEditPostData } from "../../../services/metadata";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const headerWrapper = css`
  display: flex;
  align-items: center;
  margin-bottom: 1rem;

  span {
    margin-left: 0.8rem;
  }
`;

const BatchEditConfirmation = ({
  batchAdds,
  batchDeletes,
  filteredQuery,
  handleClose,
  handleFormReset,
  isConfirmModalOpen,
}) => {
  const [confirmationError, setConfirmationError] = useState({});

  const [batchUpdate] = useMutation(BATCH_UPDATE, {
    onCompleted({ batchUpdate }) {
      toastWrapper("is-success", "Batch edit job successfully submitted.");
      handleFormReset();
      handleClose();
    },
    onError(error) {
      console.log("onError() error", error);
      toastWrapper("is-danger", error);
      handleClose();
    },
  });

  const handleConfirmationChange = (e) => {
    const filterValue = e.target.value;
    filterValue == "I understand"
      ? setConfirmationError()
      : setConfirmationError({
          confirmationText: "Confirmation text is required.",
        });
  };

  const handleBatchEditConfirm = () => {
    const cleanedPostValues = removeLabelsFromBatchEditPostData(
      batchAdds,
      batchDeletes,
      hasAdds,
      hasDeletes
    );

    batchUpdate({
      variables: {
        query: filteredQuery,
        add: cleanedPostValues.add,
        delete: cleanedPostValues.delete,
      },
    });
  };

  const hasAdds =
    batchAdds && Object.keys(batchAdds.descriptiveMetadata).length > 0;
  const hasDeletes = batchDeletes && Object.keys(batchDeletes).length > 0;

  return (
    <div
      className={`modal ${isConfirmModalOpen ? "is-active" : ""}`}
      data-testid="modal-batch-edit-confirmation"
    >
      <div className="modal-background"></div>
      <div className="modal-card" style={{ width: "85%" }}>
        <header className="modal-card-head">
          <p className="modal-card-title">Batch Edit Confirmation</p>
          <button
            className="modal-close is-large"
            aria-label="close"
            type="button"
            onClick={handleClose}
          ></button>
        </header>
        <div className="modal-card-body">
          {hasAdds && (
            <section className="content">
              <div css={headerWrapper}>
                <FontAwesomeIcon icon="plus" size="2x" />
                <span className="subtitle">Adding</span>
              </div>

              {Object.keys(batchAdds.descriptiveMetadata).map((key) => {
                return (
                  <div
                    key={key}
                    className="px-4 py-4 notification is-success is-light"
                  >
                    <h5 className="is-capitalized">{key}</h5>
                    <BatchEditConfirmationTable
                      items={batchAdds.descriptiveMetadata[key]}
                      type="add"
                    />
                  </div>
                );
              })}
            </section>
          )}

          {hasDeletes && (
            <section className={`content ${hasAdds ? "py-6" : ""}`}>
              <div css={headerWrapper}>
                <FontAwesomeIcon icon="minus-square" size="2x" />
                <span className="subtitle">Removing</span>
              </div>

              <div className="p4">
                {Object.keys(batchDeletes).map((key) => (
                  <div key={key} className="notification is-danger is-light">
                    <h5 className="is-capitalized">{key}</h5>
                    <BatchEditConfirmationTable
                      items={batchDeletes[key]}
                      type="remove"
                    />
                  </div>
                ))}
              </div>
            </section>
          )}

          <div className="columns">
            <div className="column is-three-fifths is-offset-one-fifth">
              <div className="notification is-white">
                <p className="has-text-danger has-text-centered mb-3">
                  <FontAwesomeIcon icon="exclamation-triangle" /> NOTE: This
                  will affect all works currently selected. Please proceed with
                  extreme caution.{" "}
                  <strong>To execute this change, type "I understand"</strong>
                </p>

                <UIFormInput
                  errors={confirmationError}
                  onChange={handleConfirmationChange}
                  name="confirmationText"
                  label="Confirmation Text"
                  required
                  data-testid="input-confirmation-text"
                />
              </div>
            </div>
          </div>
        </div>
        <footer className="modal-card-foot buttons is-right">
          <button
            className="button is-text"
            onClick={handleClose}
            type="button"
          >
            Cancel
          </button>
          <button
            className="button is-primary"
            disabled={confirmationError}
            onClick={handleBatchEditConfirm}
            type="button"
            data-testid="button-set-image"
          >
            Confirm changes
          </button>
        </footer>
      </div>
    </div>
  );
};

BatchEditConfirmation.propTypes = {
  batchAdds: PropTypes.object,
  batchDeletes: PropTypes.object,
  filteredQuery: PropTypes.string,
  handleClose: PropTypes.func,
  handleFormReset: PropTypes.func,
  isConfirmModalOpen: PropTypes.bool,
};

export default BatchEditConfirmation;
