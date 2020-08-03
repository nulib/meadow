import React, { useState } from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";

const UIAccordion = ({ title, testid, isVisible, children }) => {
  const [visibility, setVisibility] = useState(isVisible);
  const wrapperCss = css`
    visibility: ${visibility ? "visible" : "hidden"};
    height: ${visibility ? "auto" : "0"};
  `;
  return (
    <div className="box is-relative mt-4" data-testid={testid}>
      <h2 className="title is-size-5 mb-4">
        {title}{" "}
        <a onClick={() => setVisibility(!visibility)}>
          <FontAwesomeIcon
            icon={visibility ? "chevron-down" : "chevron-right"}
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
  isVisible: PropTypes.bool,
};

export default UIAccordion;
