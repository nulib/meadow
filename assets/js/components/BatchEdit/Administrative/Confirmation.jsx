import React, { useState } from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import UIFormInput from "@js/components/UI/Form/Input";
import { toastWrapper } from "@js/services/helpers";
import { BATCH_UPDATE } from "@js/components/BatchEdit/batch-edit.gql";
import { useMutation } from "@apollo/client";
import BatchEditConfirmationTable from "@js/components/BatchEdit/ConfirmationTable";
import { removeLabelsFromBatchEditPostData } from "@js/services/metadata";
import { useHistory } from "react-router-dom";
import { Button } from "@nulib/admin-react-components";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const verifyInputWrapper = css`
  width: 100%;
  max-width: 400px;
  display: inline-block;
`;

const BatchEditConfirmation = ({
  batchAdds,
  batchDeletes,
  batchReplaces,
  batchVisibility,
  filteredQuery,
  handleClose,
  handleFormReset,
  isConfirmModalOpen,
  numberOfResults,
}) => {
  const history = useHistory();
  const [confirmationError, setConfirmationError] = useState({});

  const [batchUpdate] = useMutation(BATCH_UPDATE, {
    onCompleted({ batchUpdate }) {
      toastWrapper("is-success", "Batch edit job successfully submitted.");
      handleFormReset();
      handleClose();
      history.push("/search");
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
      batchReplaces,
      hasAdds,
      hasDeletes,
      hasReplaces
    );
    if (hasVisibility) {
      cleanedPostValues.replace["visibility"] = {
        id: batchVisibility.id,
        scheme: batchVisibility.scheme,
      };
    }

    batchUpdate({
      variables: {
        query: filteredQuery,
        add: cleanedPostValues.add,
        delete: cleanedPostValues.delete,
        replace: cleanedPostValues.replace,
      },
    });
  };

  const hasAdds =
    batchAdds && Object.keys(batchAdds.administrativeMetadata).length > 0;

  const hasDeletes =
    batchDeletes && !Object.values(batchDeletes).every((item) => !item.length);

  const hasReplaces =
    batchReplaces &&
    Object.keys(batchReplaces.administrativeMetadata).length > 0;

  const hasVisibility =
    batchVisibility && Object.keys(batchVisibility).length > 0;

  const hasDataToPost = hasAdds || hasDeletes || hasReplaces || hasVisibility;

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
              <h3>Adding</h3>
              <BatchEditConfirmationTable
                itemsObj={batchAdds.administrativeMetadata}
                type="add"
              />
            </section>
          )}

          {hasDeletes && (
            <section className={`content ${hasAdds ? "py-6" : ""}`}>
              <h3>Removing</h3>
              <BatchEditConfirmationTable
                itemsObj={batchDeletes}
                type="remove"
              />
            </section>
          )}

          {(hasReplaces || hasVisibility) && (
            <section className="content">
              <h3>Replacing</h3>
              <BatchEditConfirmationTable
                itemsObj={{
                  ...batchReplaces.administrativeMetadata,
                  ...(batchVisibility.id && {
                    visibility: batchVisibility,
                  }),
                }}
                type="replace"
              />
            </section>
          )}

          {hasDataToPost ? (
            <div className="notification is-white has-text-centered">
              <p className="has-text-danger mb-3">
                <FontAwesomeIcon icon="exclamation-triangle" /> NOTE: This batch
                edit will affect {numberOfResults} works. To execute this
                change, type "I understand"
              </p>

              <div css={verifyInputWrapper}>
                <UIFormInput
                  onChange={handleConfirmationChange}
                  name="confirmationText"
                  label="Confirmation Text"
                  required
                  data-testid="input-confirmation-text"
                />
              </div>
            </div>
          ) : (
            <p className="notification is-white">
              No data currently selected to batch update.
            </p>
          )}
        </div>

        <footer className="modal-card-foot buttons is-right">
          <Button isText onClick={handleClose}>
            Cancel
          </Button>
          <Button
            isPrimary
            disabled={confirmationError || !hasDataToPost}
            onClick={handleBatchEditConfirm}
            data-testid="button-set-image"
          >
            Confirm changes
          </Button>
        </footer>
      </div>
    </div>
  );
};

BatchEditConfirmation.propTypes = {
  batchAdds: PropTypes.object,
  batchDeletes: PropTypes.object,
  batchReplaces: PropTypes.object,
  filteredQuery: PropTypes.string,
  handleClose: PropTypes.func,
  handleFormReset: PropTypes.func,
  isConfirmModalOpen: PropTypes.bool,
  numberOfResults: PropTypes.number,
};

export default BatchEditConfirmation;
