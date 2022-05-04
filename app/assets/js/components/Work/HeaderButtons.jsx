import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { IconChain } from "@js/components/Icon";

export default function WorkHeaderButtons({
  handleCreateSharableBtnClick,
  handlePublishClick,
  hasCollection,
  published,
}) {
  const isPublishBtnDisabled = !hasCollection && !published;

  return (
    <div className="buttons" data-testid="work-header-buttons">
      <Button
        isPrimary
        onClick={handleCreateSharableBtnClick}
        data-testid="button-sharable-link"
      >
        <IconChain />
        <span>Get sharable link</span>
      </Button>
      <AuthDisplayAuthorized level="MANAGER">
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
      </AuthDisplayAuthorized>
    </div>
  );
}

WorkHeaderButtons.propTypes = {
  handleCreateSharableBtnClick: PropTypes.func,
  handlePublishClick: PropTypes.func,
  hasCollection: PropTypes.bool,
  published: PropTypes.bool,
};
