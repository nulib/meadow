import React from "react";

/** @jsx jsx */
import { jsx } from "@emotion/react";
import styled from "@emotion/styled";

const TooltipBody = styled.div`
  display: none;
  position: absolute;
`;

const TooltipWrapper = styled.div`
  position: relative;
  &:hover {
    .tooltip-header > button > span {
      color: ${(props) => props.highlightColor} !important;
    }
    .tooltip-body {
      display: block;
      background: ${(props) => props.highlightColor};
      z-index: 99999;
      padding: 0.25rem;
      margin: 0;
      border-radius: 6px;
      box-shadow: 0 0.5em 1em -0.125em rgba(0, 0, 0, 0.1),
        0 0px 0 1px rgba(0, 0, 0, 0.02);

      &::before {
        width: 0;
        height: 0;
        display: inline-block;
        border: 6px solid transparent;
        border-bottom-color: ${(props) => props.highlightColor};
        content: "";
        position: absolute;
        top: calc(-7px - 0.25rem);
        left: 1rem;
        margin-left: -3px;
      }
    }
  }
`;

const UITooltip = ({ highlightColor = "#4e2a84", children }) => {
  if (!Array.isArray(children)) {
    return null;
  }

  const tooltipHeader = children.find(
    (header) => header.props.className === "tooltip-header"
  );
  const tooltipContent = children.find(
    (body) => body.props.className === "tooltip-content"
  );

  return (
    <TooltipWrapper
      highlightColor={highlightColor}
      data-testid="tooltip-wrapper"
    >
      {tooltipHeader}
      {tooltipContent && (
        <TooltipBody className="tooltip-body" data-testid="tooltip-body">
          {tooltipContent}
        </TooltipBody>
      )}
    </TooltipWrapper>
  );
};

export default UITooltip;
