import React from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import PropTypes from "prop-types";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const cacheNotification = css`
  display: flex;
  justify-content: space-between;
  align-items: center;
`;

export default function UICodeListCacheRefresh({ handleClick }) {
  return (
    <div
      data-testid="cache-refresh"
      className="notification is-size-7"
      css={cacheNotification}
    >
      <p>
        <span className="icon">
          <FontAwesomeIcon icon="bell" />
        </span>
        Role and Authority fields are using cached dropdown values (as these
        rarely change).
      </p>
      <button
        data-testid="button-cache-refresh"
        type="button"
        className="button is-text is-small"
        onClick={handleClick}
      >
        Sync with latest values
      </button>
    </div>
  );
}

UICodeListCacheRefresh.propTypes = {
  handleClick: PropTypes.func,
};
