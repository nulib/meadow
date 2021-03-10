import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import UISticky from "@js/components/UI/Sticky";
import UIIconText from "@js/components/UI/IconText";
import IconEdit from "@js/components/Icon/Edit";
/** @jsx jsx */
import { css, jsx } from "@emotion/react";

const wrapperBar = css`
  display: flex;
  align-items: center;
  justify-content: space-between;
`;

function MultiEditBar({ currentIndex, handleMultiNavClick, totalItems }) {
  return (
    <UISticky>
      <div className="box notification is-warning is-light">
        <div data-testid="multi-edit-bar" css={wrapperBar}>
          <Button
            data-testid="multi-edit-back-button"
            disabled={currentIndex === 0}
            onClick={() => handleMultiNavClick(currentIndex - 1)}
          >
            <FontAwesomeIcon icon="chevron-left" />
          </Button>
          <p className="is-size-5" data-testid="multi-edit-display-message">
            <UIIconText icon={<IconEdit />}>
              You are editing Work <strong>{currentIndex + 1}</strong> out of{" "}
              <strong>{totalItems}</strong>
            </UIIconText>
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
    </UISticky>
  );
}

MultiEditBar.propTypes = {
  currentIndex: PropTypes.number,
  handleMultiNavClick: PropTypes.func,
  totalItems: PropTypes.number,
};

export default MultiEditBar;
