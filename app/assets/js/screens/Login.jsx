import React, { useContext } from "react";
import { AuthContext } from "../components/Auth/Auth";
import { Redirect } from "react-router-dom";
import Layout from "./Layout";
import { IconAlert } from "@js/components/Icon";
import UIIconText from "@js/components/UI/IconText";
import { Notification } from "@nulib/design-system";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
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
      <div className="section" css={wrapper} className="">
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
