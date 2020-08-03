import React, { useState } from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";

const UIAccordion = ({ title, testid, defaultOpen = true, children }) => {
  const [isContentOpen, setIsContentOpen] = useState(defaultOpen);
  const wrapperCss = css`
    visibility: ${isContentOpen ? "visible" : "hidden"};
    height: ${isContentOpen ? "auto" : "0"};
  `;
  return (
    <div className="box is-relative mt-4" data-testid={testid}>
      <h2 className="title is-size-5 mb-4">
        {title}{" "}
        <a onClick={() => setIsContentOpen(!isContentOpen)}>
          <FontAwesomeIcon
            icon={isContentOpen ? "chevron-down" : "chevron-right"}
          />
        </a>
      </h2>
      <div css={wrapperCss}>{children}</div>
    </div>
  );
};

UIAccordion.propTypes = {
  title: PropTypes.string,
  children: PropTypes.node,
  testid: PropTypes.string,
  defaultOpen: PropTypes.bool,
};

export default UIAccordion;
