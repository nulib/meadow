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
    background: ${(props) => props.highlightColor};
    .tooltip-body {
      display: block;
      background: ${(props) => props.highlightColor};
      z-index: 99999;
      padding-left: 1rem;
    }
  }
`;

const UITooltip = ({ highlightColor = "whitesmoke", children }) => {
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
