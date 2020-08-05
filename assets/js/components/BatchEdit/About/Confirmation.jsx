import React, { useEffect } from "react";
import PropTypes, { object } from "prop-types";
import {
  CONTROLLED_METADATA,
  UNCONTROLLED_METADATA,
  PHYSICAL_METADATA,
  RIGHTS_METADATA,
  IDENTIFIER_METADATA,
  OTHER_METADATA,
} from "../../../services/metadata";
/** @jsx jsx */
import { css, jsx } from "@emotion/core";

const addWrapperCss = css`
  border: 1px solid green;
`;

const BatchEditConfirmation = ({
  addMetadata,
  removeMetadata,
  isModalOpen,
  handleClose,
}) => {
  console.log("Here!", addMetadata, isModalOpen, handleClose);
  const metadataItems = CONTROLLED_METADATA.concat(
    UNCONTROLLED_METADATA,
    PHYSICAL_METADATA,
    RIGHTS_METADATA,
    IDENTIFIER_METADATA,
    OTHER_METADATA
  );
  useEffect(() => {
    //Get labels of metadata for display
    Object.keys(addMetadata).map((item) => {
      let obj = metadataItems.find((x) => x.name === item);
      addMetadata[item] = { ...obj, metadata: addMetadata[item] };
    });
  }, [addMetadata]);

  return (
    <div
      className={`modal ${isModalOpen ? "is-active" : ""}`}
      data-testid="modal-confirmation"
    >
      <div className="modal-background"></div>
      <div className="modal-card" style={{ width: "85%" }}>
        <header className="modal-card-head">
          <p className="modal-card-title">Batch Edit Confirmation</p>
          <button
            className="modal-close is-large"
            aria-label="close"
            onClick={handleClose}
          ></button>
        </header>
        <section className="modal-card-body">
          <h3 className="title is-size-5">Adding </h3>
          <ul className="px-4 py-4" css={addWrapperCss}>
            {Object.keys(addMetadata).map(
              (items) =>
                Array.isArray(addMetadata[items].metadata) &&
                addMetadata[items].metadata.map((item, index) => (
                  <li key={`${item}-${index}`} className="py-2">
                    <strong>+ {addMetadata[items].label}: </strong>
                    {/*Check If the metadata for this field is an array of strings */}
                    {typeof addMetadata[items].metadata[index] === "string"
                      ? addMetadata[items].metadata[index]
                      : addMetadata[items].metadata[index].roleId}
                  </li>
                ))
            )}

            {Object.keys(addMetadata).map(
              (items) =>
                !Array.isArray(addMetadata[items].metadata) &&
                addMetadata[items].metadata && (
                  <li className="py-2">
                    <strong>+ {addMetadata[items].label}: </strong>
                    {addMetadata[items].metadata}
                  </li>
                )
            )}
          </ul>
        </section>
        <footer className="modal-card-foot buttons is-right">
          <button className="button is-text" onClick={handleClose}>
            Cancel
          </button>
          <button
            className="button is-primary"
            onClick={() => {
              handleBatchEditConfirm();
            }}
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
};

export default BatchEditConfirmation;
