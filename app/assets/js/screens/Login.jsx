import React, { useContext } from "react";
/** @jsx jsx */
import { css, jsx } from "@emotion/react";

import { AuthContext } from "../components/Auth/Auth";
import { IconAlert } from "@js/components/Icon";
import Layout from "./Layout";
import { Notification } from "@nulib/design-system";
import { Redirect } from "react-router-dom";
import UIIconText from "@js/components/UI/IconText";

const wrapper = css`
  height: 75vh;
  display: flex;
  align-items: center;
`;

const ScreensLogin = () => {
  const me = useContext(AuthContext);

  if (me) return <Redirect to="/" />;

  return (
    <Layout>
      <div className="section" css={wrapper}>
        <div className="container has-text-centered">
          <Notification isWarning className="is-size-5">
            <UIIconText icon={<IconAlert />}>
              Northwestern University Staff access only. Please login to access
              Meadow.
            </UIIconText>
          </Notification>
        </div>
      </div>
    </Layout>
  );
};

export default ScreensLogin;
