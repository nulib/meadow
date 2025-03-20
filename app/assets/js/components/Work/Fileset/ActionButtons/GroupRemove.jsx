/** @jsx jsx */

import React from "react";
import { css, jsx } from "@emotion/react";

const WorkFilesetActionButtonsGroupRemove = ({
  fileSetId,
  handleUpdateFileSet,
}) => {
  const button = css`
    color: var(--colors-richBlack50);
    text-transform: none;
    text-decoration: underline;
  `;

  const handleRemoveClick = () => {
    handleUpdateFileSet(fileSetId, null);
  };

  return (
    <button
      className="button is-text"
      css={button}
      onClick={handleRemoveClick}
      data-testid="fileset-group-remove"
    >
      Detach
    </button>
  );
};

export default WorkFilesetActionButtonsGroupRemove;
