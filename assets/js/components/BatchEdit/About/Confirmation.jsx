import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import {
  CONTROLLED_METADATA,
  UNCONTROLLED_METADATA,
  PHYSICAL_METADATA,
  RIGHTS_METADATA,
  IDENTIFIER_METADATA,
  OTHER_METADATA,
} from "../../../services/metadata";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import UIFormField from "../../UI/Form/Field";
import UIFormInput from "../../UI/Form/Input";
import { toastWrapper } from "../../../services/helpers";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";

const addWrapperCss = css`
  border: 1px solid green;
`;

const removeWrapperCss = css`
  border: 1px solid red;
`;

const confirmationNote =
  'NOTE: This will affect all works currently selected. Please proceed with extreme caution. To execute this change, type "I understand"';

const mockDeleteMetadata = {
  contributor: [
    {
      role: { scheme: "MARC_RELATOR", id: "aut" },
      term: "http://id.loc.gov/authorities/names/n79091588",
    },
  ],
  genre: [{ term: "http://vocab.getty.edu/aat/300026031" }],
  description: "123 this is set to be removed",
};

const BatchEditConfirmation = ({
  addMetadata,
  removeMetadata,
  isConfirmModalOpen,
  handleClose,
}) => {
  const [confirmationError, setConfirmationError] = useState({});
  const [parsedAddMetadata, setParsedAddMetadata] = useState();
  const [parsedDeleteMetadata, setParsedDeleteMetadata] = useState();

  const metadataItems = CONTROLLED_METADATA.concat(
    UNCONTROLLED_METADATA,
    PHYSICAL_METADATA,
    RIGHTS_METADATA,
    IDENTIFIER_METADATA,
    OTHER_METADATA
  );

  useEffect(() => {
    let parsedAddData = {};
    Object.keys(addMetadata).map((key) => {
      let obj = metadataItems.find((item) => item.name === key);
      parsedAddData[key] = { ...obj, metadata: addMetadata[key] };
    });
    setParsedAddMetadata(parsedAddData);

    let parsedDeleteData = {};
    Object.keys(mockDeleteMetadata).map((key) => {
      let obj = metadataItems.find((item) => item.name === key);
      parsedDeleteData[key] = { ...obj, metadata: mockDeleteMetadata[key] };
    });
    setParsedDeleteMetadata(parsedDeleteData);
  }, []);

  const handleConfirmationChange = (e) => {
    const filterValue = e.target.value;
    filterValue == "I understand"
      ? setConfirmationError()
      : setConfirmationError({
          confirmationText: "Confirmation text is required.",
        });
  };

  const handleBatchEditConfirm = () => {
    toastWrapper(
      "is-success",
      "Form successfully submitted.  Check the console for form values."
    );
    handleClose();
  };

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
          <section>
            <h3 className="title is-size-5">Adding </h3>
            <ul className="px-4 py-4" css={addWrapperCss}>
              {parsedAddMetadata &&
                Object.keys(parsedAddMetadata).map(
                  (key) =>
                    Array.isArray(parsedAddMetadata[key].metadata) &&
                    parsedAddMetadata[key].metadata.map((innerKey, index) => (
                      <li key={(innerKey, index)} className="py-2">
                        <FontAwesomeIcon icon="plus" />
                        <strong> {parsedAddMetadata[key].label}: </strong>
                        {/*Check If the metadata for this field is an array of strings */}
                        {typeof parsedAddMetadata[key].metadata[index] ===
                        "string"
                          ? parsedAddMetadata[key].metadata[index]
                          : `${parsedAddMetadata[key].metadata[index].label},
                      ${parsedAddMetadata[key].metadata[index].termId},
                      ${parsedAddMetadata[key].metadata[index].roleId}`}
                      </li>
                    ))
                )}

              {parsedAddMetadata &&
                Object.keys(parsedAddMetadata).map(
                  (key) =>
                    !Array.isArray(parsedAddMetadata[key].metadata) &&
                    parsedAddMetadata[key].metadata && (
                      <li key={key} className="py-2">
                        <FontAwesomeIcon icon="plus" />
                        <strong> {parsedAddMetadata[key].label}: </strong>
                        {parsedAddMetadata[key].metadata}
                      </li>
                    )
                )}
            </ul>
          </section>

          <section className="py-6">
            <h3 className="title is-size-5">Removing </h3>
            <ul className="px-4 py-4" css={removeWrapperCss}>
              {parsedDeleteMetadata &&
                Object.keys(parsedDeleteMetadata).map(
                  (key) =>
                    Array.isArray(parsedDeleteMetadata[key].metadata) &&
                    parsedDeleteMetadata[key].metadata.map(
                      (innerKey, index) => (
                        <li key={(innerKey, index)} className="py-2">
                          <FontAwesomeIcon icon="minus" />
                          <strong> {parsedDeleteMetadata[key].label}: </strong>
                          {/*Check If the metadata for this field is an array of strings */}
                          {typeof parsedDeleteMetadata[key].metadata[index] ===
                          "string"
                            ? parsedDeleteMetadata[key].metadata[index]
                            : parsedDeleteMetadata[key].metadata[index].term}
                        </li>
                      )
                    )
                )}

              {parsedDeleteMetadata &&
                Object.keys(parsedDeleteMetadata).map(
                  (key) =>
                    !Array.isArray(parsedDeleteMetadata[key].metadata) &&
                    parsedDeleteMetadata[key].metadata && (
                      <li key={key} className="py-2">
                        <FontAwesomeIcon icon="minus" />
                        <strong> {parsedDeleteMetadata[key].label}: </strong>
                        {parsedDeleteMetadata[key].metadata}
                      </li>
                    )
                )}
            </ul>
          </section>
          <div className="columns">
            <div className="column is-half">
              <UIFormField label={confirmationNote}>
                <UIFormInput
                  errors={confirmationError}
                  onChange={handleConfirmationChange}
                  name="confirmationText"
                  label="Confirmation Text"
                  required
                  data-testid="input-confirmation-text"
                />
              </UIFormField>
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
            onClick={() => {
              handleBatchEditConfirm();
            }}
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
  addMetadata: PropTypes.object,
  removeMetadata: PropTypes.object,
  handleClose: PropTypes.func,
  isConfirmModalOpen: PropTypes.bool,
};

export default BatchEditConfirmation;
