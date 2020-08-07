import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";

function setupRemoveList(items) {
  const newList = items.map((item) => {
    var arr = item.key.split("|");
    return {
      key: item.key,
      label: `${arr[arr.length - 1]} ${arr[0]} (${item.doc_count})`,
    };
  });

  return newList;
}

export default function BatchEditAboutModalRemove({
  closeModal,
  currentRemoveField,
  handleSave,
  isRemoveModalOpen,
  items = [],
}) {
  if (!currentRemoveField) return null;

  const [removeList, setRemoveList] = useState([]);
  const [selectedItems, setSelectedItems] = useState([]);

  useEffect(() => {
    if (items.length > 0) {
      setRemoveList(setupRemoveList(items));
    }
  }, [items]);

  function handleChange({ key }) {
    const index = selectedItems.indexOf(key);

    if (index === -1) {
      return setSelectedItems([...removeList, key]);
    }
    let list = [...removeList];
    list.splice(index, 1);
    setSelectedItems(list);
  }

  function handleSaveClick() {
    handleSave();
  }

  function isItemSelected(item) {
    return selectedItems.indexOf(item.key) > -1;
  }

  return (
    <div className={`modal ${isRemoveModalOpen ? "is-active" : ""}`}>
      <div className="modal-background"></div>
      <div className="modal-card">
        <header className="modal-card-head">
          <p className="modal-card-title">
            Batch remove the following{" "}
            <strong>{currentRemoveField.label}</strong>s
          </p>
          <button
            type="button"
            className="delete"
            onClick={closeModal}
            aria-label="close"
          ></button>
        </header>
        <section className="modal-card-body">
          {removeList.map((item) => (
            <div className="field" key={`${item.key}`}>
              <div className="control">
                <label className="checkbox">
                  <input
                    type="checkbox"
                    checked={isItemSelected(item)}
                    onChange={() => handleChange(item)}
                  />{" "}
                  {item.label}
                </label>
              </div>
            </div>
          ))}
        </section>
        <footer className="modal-card-foot">
          <button
            type="button"
            className="button is-primary"
            onClick={handleSaveClick}
          >
            Confirm selection
          </button>
          <button type="button" className="button" onClick={closeModal}>
            Cancel
          </button>
        </footer>
      </div>
    </div>
  );
}

BatchEditAboutModalRemove.propTypes = {
  closeModal: PropTypes.func,
  currentRemoveField: PropTypes.object,
  handleSave: PropTypes.func,
  isRemoveModalOpen: PropTypes.bool,
  items: PropTypes.array,
};
