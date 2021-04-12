import React from "react";
import PropTypes from "prop-types";
import classNames from "classnames";
import useEnvironment from "@js/hooks/useEnvironment";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";

function UILayoutMain({ children }) {
  const env = useEnvironment();
  const devBg = localStorage.getItem("devBg");

  // Sets bg color for the DEV environment only
  const wrapper = css`
    background: ${(env !== "PRODUCTION" && devBg) || false};
  `;

  return (
    <main
      css={wrapper}
      className={classNames({
        // "has-background-grey": env === "STAGING",
        // The following are just helper classes which may or may not get used
        "is-dev-environment": env === "DEV",
        "is-staging-environment": env === "STAGING",
        "is-production-environment": env === "PRODUCTION",
      })}
    >
      {children}
    </main>
  );
}

UILayoutMain.propTypes = {};

export default UILayoutMain;
