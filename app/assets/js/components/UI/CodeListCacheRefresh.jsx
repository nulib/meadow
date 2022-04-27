import React from "react";
import PropTypes from "prop-types";
import { IconBell } from "@js/components/Icon";
import { Notification } from "@nulib/design-system";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const cacheNotification = css`
  display: flex;
  justify-content: space-between;
  align-items: center;
`;

export default function UICodeListCacheRefresh({ handleClick }) {
  return (
    <Notification
      data-testid="cache-refresh"
      className="is-size-7"
      css={cacheNotification}
    >
      <p>
        <IconBell />
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
    </Notification>
  );
}

UICodeListCacheRefresh.propTypes = {
  handleClick: PropTypes.func,
};
