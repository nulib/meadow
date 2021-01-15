import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
/** @jsx jsx */
import { css, jsx } from "@emotion/react";

const wrapperBar = css`
  display: flex;
  align-items: center;
  justify-content: space-between;
`;

function MultiEditBar({ currentIndex, handleMultiNavClick, totalItems }) {
  return (
    <div className="box is-shadowless">
      <div data-testid="multi-edit-bar" css={wrapperBar}>
        <Button
          data-testid="multi-edit-back-button"
          disabled={currentIndex === 0}
          onClick={() => handleMultiNavClick(currentIndex - 1)}
        >
          <FontAwesomeIcon icon="chevron-left" />
        </Button>
        <p data-testid="multi-edit-display-message">
          <FontAwesomeIcon icon="sync" className="mr-2" />
          You are editing Work <strong>{currentIndex + 1}</strong> out of{" "}
          <strong>{totalItems}</strong>
        </p>
        <Button
          data-testid="multi-edit-next-button"
          disabled={currentIndex + 1 === totalItems}
          onClick={() => handleMultiNavClick(currentIndex + 1)}
        >
          <FontAwesomeIcon icon="chevron-right" />
        </Button>
      </div>
    </div>
  );
}

MultiEditBar.propTypes = {
  currentIndex: PropTypes.number,
  handleMultiNavClick: PropTypes.func,
  totalItems: PropTypes.number,
};

export default MultiEditBar;
