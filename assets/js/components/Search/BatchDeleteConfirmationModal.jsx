import React, { useState } from "react";
import PropTypes from "prop-types";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormField from "@js/components/UI/Form/Field";
import { toastWrapper } from "@js/services/helpers";
import { BATCH_DELETE } from "@js/components/BatchEdit/batch-edit.gql";
import { useMutation } from "@apollo/client";
import { useHistory } from "react-router-dom";
import { Button, Notification } from "@nulib/design-system";
import { buildSelectedItemsQuery } from "@js/services/reactive-search";
import { IconAlert } from "@js/components/Icon";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const verifyInputWrapper = css`
  width: 100%;
  max-width: 400px;
  display: inline-block;
`;

const BatchDeleteConfirmationModal = ({
  filteredQuery,
  numberOfResults,
  handleCloseClick,
  isOpen,
  selectedItems,
}) => {
  const history = useHistory();
  const [confirmationError, setConfirmationError] = useState({});
  const [batchNickname, setBatchNickname] = useState();

  const [batchDelete] = useMutation(BATCH_DELETE, {
    onCompleted({ batchDelete }) {
      toastWrapper("is-success", "Batch delete job successfully submitted.");
      handleCloseClick();
      history.push("/dashboards/batch-edit");
    },
    onError(error) {
      console.log("onError() error", error);
      toastWrapper("is-danger", error.toString());
      handleCloseClick();
    },
  });

  const handleConfirmationChange = (e) => {
    const filterValue = e.target.value;
    filterValue == "permanently delete"
      ? setConfirmationError()
      : setConfirmationError({
          confirmationText: "Confirmation text is required.",
        });
  };

  const handleNicknameChange = (e) => {
    setBatchNickname(e.target.value);
  };

  const handleBatchDeleteConfirm = () => {
    let query = "";
    if (selectedItems.length == 0) {
      query = JSON.stringify({ query: filteredQuery });
    } else {
      query = JSON.stringify({
        query: buildSelectedItemsQuery(selectedItems),
      });
    }

    batchDelete({
      variables: {
        query: query,
        nickname: batchNickname,
      },
    });
  };

  return (
    <div
      className={`modal ${isOpen ? "is-active" : ""}`}
      data-testid="select-all-modal"
    >
      <div className="modal-background"></div>
      <div className="modal-card">
        <header className="modal-card-head">
          <p className="modal-card-title">Batch Delete Works</p>
          <button
            className="delete"
            aria-label="close"
            onClick={handleCloseClick}
            data-testid="header-close-button"
          ></button>
        </header>
        <section className="modal-card-body">
          <div className="column is-two-thirds">
            <UIFormField label="Batch nickname (optional)">
              <UIFormInput
                onChange={handleNicknameChange}
                name="batchNickname"
                label="Batch Nickname"
                placeholder="Batch Nickname"
                data-testid="input-batch-nickname"
              />
            </UIFormField>
          </div>
          <Notification isDanger isCentered className="content">
            <p>
              <IconAlert /> NOTE: This batch operation will permanently delete{" "}
              {selectedItems.length || numberOfResults} works. To execute this
              change, type "<b>permanently delete</b>"
            </p>

            <div css={verifyInputWrapper}>
              <UIFormInput
                onChange={handleConfirmationChange}
                name="confirmationText"
                label="Confirmation Text"
                placeholder="permanently delete"
                required
                data-testid="input-confirmation-text"
              />
            </div>
          </Notification>
        </section>
        <footer className="modal-card-foot is-justify-content-flex-end">
          <Button
            className="button is-primary"
            disabled={confirmationError}
            data-testid="button-batch-items-delete"
            onClick={handleBatchDeleteConfirm}
          >
            <span>Confirm</span>
          </Button>
          <Button isText onClick={handleCloseClick}>
            Cancel
          </Button>
        </footer>
      </div>
    </div>
  );
};

BatchDeleteConfirmationModal.propTypes = {
  filteredQuery: PropTypes.object,
  numberOfResults: PropTypes.number,
  handleCloseClick: PropTypes.func,
  selectedItems: PropTypes.array,
  isOpen: PropTypes.bool,
};

export default BatchDeleteConfirmationModal;
