import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import {
  useBatchDispatch,
  useBatchState,
} from "../../context/batch-edit-context";
import { splitFacetKey } from "../../services/metadata";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";

const modalContent = css`
  width: 75%;
`;

function setupCandidateList(items) {
  const newList = items.map((item) => {
    const { label, role, term } = splitFacetKey(item.key);
    return {
      key: item.key,
      label: (
        <span>
          <strong>{label}</strong> - {term} - ({item.doc_count})
        </span>
      ),
    };
  });

  return newList;
}

export default function BatchEditAboutModalRemove({
  closeModal,
  currentRemoveField,
  isRemoveModalOpen,
  items = [],
}) {
  if (!currentRemoveField) return null;

  const batchState = useBatchState();
  const dispatch = useBatchDispatch();
  const [candidateList, setCandidateList] = useState([]);
  const selectedItems =
    batchState.removeItems && batchState.removeItems[currentRemoveField.name]
      ? batchState.removeItems[currentRemoveField.name]
      : [];

  useEffect(() => {
    if (items.length > 0) {
      setCandidateList(setupCandidateList(items));
    }
  }, [items]);

  function handleCheckboxChange({ key }) {
    dispatch({
      type: "updateRemoveItem",
      fieldName: currentRemoveField.name,
      key: key,
    });
  }

  return (
    <div className={`modal ${isRemoveModalOpen ? "is-active" : ""}`}>
      <div className="modal-background"></div>
      <div className="modal-content" css={modalContent}>
        <div className="box">
          <header>
            <h3 className="title">{currentRemoveField.label}</h3>
            <h4 className="subtitle">Batch remove the following entries</h4>
          </header>
          <div className="my-4">
            {candidateList.map((item) => (
              <div className="field" key={`${item.key}`}>
                <div className="control">
                  <input
                    type="checkbox"
                    checked={selectedItems.indexOf(item.key) > -1}
                    onChange={() => handleCheckboxChange(item)}
                    className="is-checkradio"
                    id={`remove-${item.key}`}
                  />{" "}
                  <label htmlFor={`remove-${item.key}`} className="checkbox">
                    {item.label}
                  </label>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
      <button
        className="modal-close is-large"
        aria-label="close"
        onClick={closeModal}
        type="button"
      ></button>
    </div>
  );
}

BatchEditAboutModalRemove.propTypes = {
  closeModal: PropTypes.func,
  currentRemoveField: PropTypes.object,
  isRemoveModalOpen: PropTypes.bool,
  items: PropTypes.array,
};
