import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import classNames from "classnames";
import UIFormField from "@js/components/UI/Form/Field";

const UIBehaviorModal = ({
  isVisible,
  behaviors,
  currentBehavior,
  onClose,
  onSave
}) => {
  const [selectedBehavior, setSelectedBehavior] = React.useState(
    currentBehavior || ""
  );

  React.useEffect(() => {
    setSelectedBehavior(currentBehavior || "");
  }, [currentBehavior, isVisible]);

  function handleCancelClick() {
    setSelectedBehavior(currentBehavior || "");
    onClose();
  }

  function handleRadioChange(e) {
    setSelectedBehavior(e.target.value);
  }

  function handleSubmit() {
    onSave(selectedBehavior);
  }

  const behaviorDefinitions = {
    individuals: "Display each canvas separately (e.g., individual images or objects)",
    continuous: "Display canvases end-to-end in a scrolling view (e.g., scrolls, long documents)",
    paged: "Display canvases as facing pages with page-turning navigation (e.g., books)"
  };

  return (
    <div
      className={classNames("modal", {
        "is-active": isVisible,
      })}
      data-testid="behavior-modal"
    >
      <div className="modal-background" onClick={handleCancelClick}></div>
      <div className="modal-card">
        <div className="modal-card-head">
          <p className="modal-card-title">Select Behavior</p>
          <button
            type="button"
            className="delete"
            aria-label="close"
            onClick={handleCancelClick}
          ></button>
        </div>
        <section className="modal-card-body">
          <UIFormField label="Choose how content is displayed">
            <div className="control" data-testid="radio-behavior">
              {behaviors.length > 0 ? (
                behaviors.map((behavior) => (
                  <div key={behavior.id} style={{ marginBottom: '1rem' }}>
                    <label className="radio">
                      <input
                        type="radio"
                        name="behavior"
                        value={behavior.id}
                        checked={selectedBehavior === behavior.id}
                        onChange={handleRadioChange}
                        style={{ marginRight: '0.5rem' }}
                      />
                      <strong>{behavior.label}</strong>
                    </label>
                    <p style={{ marginLeft: '1.5rem', color: '#666', fontSize: '0.9em' }}>
                      {behaviorDefinitions[behavior.id] || ""}
                    </p>
                  </div>
                ))
              ) : (
                <p>No behaviors available</p>
              )}
            </div>
          </UIFormField>
        </section>
        <footer className="modal-card-foot buttons is-right">
          <Button
            isText
            onClick={handleCancelClick}
            aria-label="close"
            data-testid="cancel-button"
          >
            Cancel
          </Button>
          <Button
            isPrimary
            onClick={handleSubmit}
            data-testid="submit-button"
            disabled={!selectedBehavior}
          >
            Save
          </Button>
        </footer>
      </div>
    </div>
  );
};

UIBehaviorModal.propTypes = {
  isVisible: PropTypes.bool,
  behaviors: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string.isRequired,
      label: PropTypes.string.isRequired,
    })
  ),
  currentBehavior: PropTypes.string,
  onClose: PropTypes.func.isRequired,
  onSave: PropTypes.func.isRequired,
};

export default UIBehaviorModal;
