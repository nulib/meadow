import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";

export default function WorkHeaderButtons({
  handleCreateSharableBtnClick,
  handlePublishClick,
  hasCollection,
  onOpenModal,
  published,
}) {
  return (
    <div className="buttons is-right" data-testid="work-header-buttons">
      <Button
        isPrimary
        className={`${published ? "is-outlined" : ""}`}
        data-testid="publish-button"
        onClick={handlePublishClick}
        disabled={!hasCollection}
      >
        {!published ? "Publish" : "Unpublish"}
      </Button>
      <Button
        onClick={handleCreateSharableBtnClick}
        data-testid="button-sharable-link"
      >
        <span className="icon">
          <FontAwesomeIcon icon="link" />
        </span>
        <span>Create sharable link</span>
      </Button>
      <Button isText data-testid="delete-button" onClick={onOpenModal}>
        Delete
      </Button>
    </div>
  );
}

WorkHeaderButtons.propTypes = {
  handleCreateSharableBtnClick: PropTypes.func,
  handlePublishClick: PropTypes.func,
  hasCollection: PropTypes.bool,
  onOpenModal: PropTypes.func,
  published: PropTypes.bool,
};
