import React, { useState } from "react";
import PropTypes from "prop-types";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormField from "@js/components/UI/Form/Field";
import { toastWrapper } from "@js/services/helpers";
import { BATCH_UPDATE } from "@js/components/BatchEdit/batch-edit.gql";
import { useMutation } from "@apollo/client";
import BatchEditConfirmationTable from "@js/components/BatchEdit/ConfirmationTable";
import { removeLabelsFromBatchEditPostData } from "@js/services/metadata";
import { useHistory } from "react-router-dom";
import { Button, Notification } from "@nulib/design-system";
import {
  IconAdd,
  IconReplace,
  IconAlert,
  IconTrashCan,
} from "@js/components/Icon";
import UIIconText from "@js/components/UI/IconText";
import { useCodeLists } from "@js/context/code-list-context";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const verifyInputWrapper = css`
  width: 100%;
  max-width: 400px;
  display: inline-block;
`;

const modalWrapper = css`
  margin-top: 60px;
`;

const BatchEditConfirmation = ({
  batchAdds,
  batchDeletes,
  batchReplaces,
  batchCollection,
  batchVisibility,
  filteredQuery,
  handleClose,
  handleFormReset,
  isConfirmModalOpen,
  numberOfResults,
}) => {
  const history = useHistory();
  const [confirmationError, setConfirmationError] = useState({});
  const [batchNickname, setBatchNickname] = useState();
  const codeLists = useCodeLists();

  const [batchUpdate] = useMutation(BATCH_UPDATE, {
    onCompleted({ batchUpdate }) {
      toastWrapper("is-success", "Batch edit job successfully submitted.");
      handleFormReset();
      handleClose();
      history.push("/dashboards/batch-edit");
    },
    onError(error) {
      console.log("onError() error", error);
      toastWrapper("is-danger", error.toString());
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

  const handleNicknameChange = (e) => {
    setBatchNickname(e.target.value);
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

    if (hasCollection) {
      cleanedPostValues.replace.collectionId = batchCollection.id;
    }

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
        nickname: batchNickname,
      },
    });
  };

  const hasAdds =
    batchAdds &&
    (Object.keys(batchAdds.administrativeMetadata).length > 0 ||
      Object.keys(batchAdds.descriptiveMetadata).length > 0);

  const hasDeletes =
    batchDeletes && !Object.values(batchDeletes).every((item) => !item.length);

  const hasReplaces =
    batchReplaces &&
    (Object.keys(batchReplaces.administrativeMetadata).length > 0 ||
      Object.keys(batchReplaces.descriptiveMetadata).length > 0 ||
      batchReplaces.published);

  const hasCollection =
    batchCollection && Object.keys(batchCollection).length > 0;

  const hasVisibility =
    batchVisibility && Object.keys(batchVisibility).length > 0;

  const hasDataToPost =
    hasAdds || hasDeletes || hasReplaces || hasCollection || hasVisibility;

  return (
    <div
      className={`modal ${isConfirmModalOpen ? "is-active" : ""}`}
      css={modalWrapper}
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

        <div className="modal-card-body has-background-light">
          {hasAdds && (
            <section className="box content" data-testid="confirmation-adds">
              <h3>
                <UIIconText icon={<IconAdd />}>Adding</UIIconText>
              </h3>
              <BatchEditConfirmationTable
                codeLists={codeLists}
                itemsObj={{
                  ...batchAdds.administrativeMetadata,
                  ...batchAdds.descriptiveMetadata,
                }}
                type="add"
              />
            </section>
          )}

          {hasDeletes && (
            <section
              className={`box content`}
              data-testid="confirmation-deletes"
            >
              <h3>
                <UIIconText icon={<IconTrashCan />}>Removing</UIIconText>
              </h3>
              <BatchEditConfirmationTable
                codeLists={codeLists}
                itemsObj={batchDeletes}
                type="remove"
              />
            </section>
          )}

          {(hasReplaces || hasCollection || hasVisibility) && (
            <section
              className="box content"
              data-testid="confirmation-replaces"
            >
              <h3>
                <UIIconText icon={<IconReplace />}>Replacing</UIIconText>
              </h3>
              <BatchEditConfirmationTable
                codeLists={codeLists}
                itemsObj={{
                  ...batchReplaces.administrativeMetadata,
                  ...batchReplaces.descriptiveMetadata,
                  ...(batchCollection &&
                    batchCollection.title && {
                      collection: batchCollection.title,
                    }),
                  ...(batchVisibility &&
                    batchVisibility.id && {
                      visibility: batchVisibility,
                    }),
                  ...(batchReplaces.published && {
                    published: batchReplaces.published.publish
                      ? "Publish works"
                      : "Unpublish works",
                  }),
                }}
                type="replace"
              />
            </section>
          )}

          {hasDataToPost ? (
            <div className="box">
              <div className="mb-4">
                <UIFormField label="Batch nickname">
                  <UIFormInput
                    onChange={handleNicknameChange}
                    name="batchNickname"
                    label="Batch Nickname"
                    placeholder="Batch Nickname"
                    data-testid="input-batch-nickname"
                  />
                  <p className="help">
                    Nicknames help identify Batch Edit jobs in the dashboard
                  </p>
                </UIFormField>
              </div>
            </div>
          ) : (
            <Notification className="is-white">
              No data currently selected to batch update.
            </Notification>
          )}

          <Notification isDanger isCentered className="content">
            <div className="block">
              <UIIconText icon={<IconAlert />} isCentered>
                This batch edit will affect {numberOfResults} works. To execute
                this change, type "I understand"
              </UIIconText>
            </div>

            <div css={verifyInputWrapper}>
              <UIFormInput
                onChange={handleConfirmationChange}
                name="confirmationText"
                label="Confirmation Text"
                placeholder="I understand"
                required
                data-testid="input-confirmation-text"
              />
            </div>
          </Notification>
        </div>

        <footer className="modal-card-foot buttons is-right">
          <Button isText onClick={handleClose}>
            Cancel
          </Button>
          <Button
            isPrimary
            disabled={confirmationError || !hasDataToPost}
            onClick={handleBatchEditConfirm}
            data-testid="button-submit"
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
  batchVisibility: PropTypes.object,
  batchCollection: PropTypes.object,
  filteredQuery: PropTypes.string,
  handleClose: PropTypes.func,
  handleFormReset: PropTypes.func,
  isConfirmModalOpen: PropTypes.bool,
  numberOfResults: PropTypes.number,
};

export default BatchEditConfirmation;
