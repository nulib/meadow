import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import {
  useBatchDispatch,
  useBatchState,
} from "../../context/batch-edit-context";
import { splitFacetKey } from "../../services/metadata";
import { Button } from "@nulib/design-system";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
import { sortItemsArray } from "@js/services/helpers";

const modalContent = css`
  width: 75%;
`;

function setupCandidateList(items) {
  const newList = items.map((item) => {
    const { label, role, term } = splitFacetKey(item.key);
    return {
      key: item.key,
      title: label,
      label: (
        <span>
          <strong>{label}</strong> - {term} - ({item.doc_count})
        </span>
      ),
    };
  });
  return sortItemsArray(newList, "title");
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
    <div
      className={`modal ${isRemoveModalOpen ? "is-active" : ""}`}
      data-testid="modal-remove"
    >
      <div className="modal-background"></div>
      <div className="modal-content" css={modalContent}>
        <div className="box">
          <header>
            <h3 className="title" data-testid="field-title">
              {currentRemoveField.label}
            </h3>
            <h4 className="subtitle">
              Select values to remove from all batch Works
            </h4>
          </header>
          <div className="my-4">
            {candidateList.map((item) => (
              <div
                className="field"
                key={`${item.key}`}
                data-testid="checkbox-field"
              >
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
          <footer>
            <div className="buttons is-right">
              <Button isLight onClick={closeModal} data-testid="close-button">
                Save &amp; close
              </Button>
            </div>
          </footer>
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
