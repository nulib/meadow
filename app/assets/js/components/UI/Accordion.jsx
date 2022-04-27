import React, { useState } from "react";
import PropTypes from "prop-types";
import { IconArrowDown, IconArrowRight } from "@js/components/Icon";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";

const UIAccordion = ({ title, testid, defaultOpen = true, children }) => {
  const [isContentOpen, setIsContentOpen] = useState(defaultOpen);
  const wrapperCss = css`
    visibility: ${isContentOpen ? "visible" : "hidden"};
    height: ${isContentOpen ? "auto" : "0"};
  `;
  return (
    <div className="box is-relative mt-4" data-testid={testid}>
      <div className="content">
        <h3 className="mb-4">
          {title}{" "}
          <a onClick={() => setIsContentOpen(!isContentOpen)}>
            {isContentOpen ? <IconArrowDown /> : <IconArrowRight />}
          </a>
        </h3>
      </div>
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
