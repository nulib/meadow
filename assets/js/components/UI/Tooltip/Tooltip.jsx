import React from "react";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const tooltipBody = css`
  display: none;
  position: absolute;
  top: 100%;
  left: 0;
`;
const tooltipWrapper = css`
  position: relative;
  &:hover {
    margin-bottom: 2em;
    .tooltip-body {
      display: block;
    }
  }
`;

const UITooltip = (props = {}) => {
  if (!Array.isArray(props.children)) {
    return null;
  }

  const tooltipHeader = props.children.find(
    (header) => header.props.className === "tooltip-header"
  );
  const tooltipContent = props.children.find(
    (body) => body.props.className === "tooltip-content"
  );

  return (
    <div css={tooltipWrapper} data-testid="tooltip-wrapper">
      {tooltipHeader}
      {tooltipContent && (
        <div
          css={tooltipBody}
          className="tooltip-body"
          data-testid="tooltip-body"
        >
          {tooltipContent}
        </div>
      )}
    </div>
  );
};

export default UITooltip;
