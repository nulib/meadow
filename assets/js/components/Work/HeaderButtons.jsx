import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";

export default function WorkHeaderButtons({
  handleCreateSharableBtnClick,
  handlePublishClick,
  hasCollection,
  published,
}) {
  const isPublishBtnDisabled = !hasCollection && !published;

  return (
    <div className="buttons is-right" data-testid="work-header-buttons">
      <Button
        onClick={handleCreateSharableBtnClick}
        data-testid="button-sharable-link"
      >
        <span className="icon">
          <FontAwesomeIcon icon="link" />
        </span>
        <span>Create sharable link</span>
      </Button>
      <Button
        className={`${published ? "is-outlined" : "has-tooltip-multiline"}`}
        data-testid="publish-button"
        onClick={handlePublishClick}
        disabled={isPublishBtnDisabled}
        data-tooltip={
          isPublishBtnDisabled
            ? "A work must belong to a Collection in order to be published.  Add to a Collection in the Administrative tab below."
            : undefined
        }
      >
        {!published ? "Publish" : "Unpublish"}
      </Button>
    </div>
  );
}

WorkHeaderButtons.propTypes = {
  handleCreateSharableBtnClick: PropTypes.func,
  handlePublishClick: PropTypes.func,
  hasCollection: PropTypes.bool,
  published: PropTypes.bool,
};
