import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import classNames from "classnames";
import UIFormField from "@js/components/UI/Form/Field";

/** @jsx jsx */
import { jsx } from "@emotion/react";
import styled from "@emotion/styled";

const PreviewContainer = styled.div`
  margin-left: 1.5rem;
  margin-top: 0.5rem;
  display: flex;
  align-items: center;
  gap: ${props => props.gap || '8px'};
`;

const Thumbnail = styled.img`
  width: 45px;
  height: 30px;
  object-fit: cover;
  border: 1px solid #ddd;
  border-radius: 2px;
  margin-right: ${props => props.touching ? '-1px' : '0'};
`;

const PagedGroup = styled.div`
  display: flex;
  gap: 0px;
`;

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
    individuals: "Display each file set separately (e.g., photographs)",
    continuous: "Display file sets end-to-end as a single view (e.g., scrolls)",
    paged: "Display file sets as facing pages (e.g., books)"
  };

  const renderPreview = (behaviorId) => {
    const placeholderImage = "/images/placeholder.png";

    switch (behaviorId) {
      case 'individuals':
        return (
          <PreviewContainer>
            <Thumbnail src={placeholderImage} alt="" />
            <Thumbnail src={placeholderImage} alt="" />
            <Thumbnail src={placeholderImage} alt="" />
          </PreviewContainer>
        );
      case 'continuous':
        return (
          <PreviewContainer gap="0px">
            <Thumbnail src={placeholderImage} alt="" touching />
            <Thumbnail src={placeholderImage} alt="" touching />
            <Thumbnail src={placeholderImage} alt="" touching />
            <Thumbnail src={placeholderImage} alt="" touching />
            <Thumbnail src={placeholderImage} alt="" />
          </PreviewContainer>
        );
      case 'paged':
        return (
          <PreviewContainer>
            <Thumbnail src={placeholderImage} alt="" />
            <PagedGroup>
              <Thumbnail src={placeholderImage} alt="" touching />
              <Thumbnail src={placeholderImage} alt="" />
            </PagedGroup>
            <PagedGroup>
              <Thumbnail src={placeholderImage} alt="" touching />
              <Thumbnail src={placeholderImage} alt="" />
            </PagedGroup>
          </PreviewContainer>
        );
      default:
        return null;
    }
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
          <p className="modal-card-title">Select Display Type</p>
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
                      <strong>{behavior.label}{behavior.id === 'individuals' ? ' (Default)' : ''}</strong>
                    </label>
                    <p style={{ marginLeft: '1.5rem', color: '#666', fontSize: '0.9em' }}>
                      {behaviorDefinitions[behavior.id] || ""}
                    </p>
                    {renderPreview(behavior.id)}
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
