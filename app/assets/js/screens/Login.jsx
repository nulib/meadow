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
          <p className="is-size-6 has-text-left p-5">
            Northwestern University Libraries and its digitized collections in
            Meadow contain materials that reflect the beliefs and norms of the
            era and culture in which they were created or collected. As such,
            staff who log into Meadow may encounter imagery, language, or
            opinions related to a white supremacist, exploitative, and/or
            discriminatory culture. Additionally, some collections may contain
            sexual content or violence. The Libraries metadata staff are
            actively working to remediate issues of outdated, inaccurate,
            objectifying or disrespectful language that describes our
            collections and welcome suggestions, questions, or comments.
          </p>
        </div>
      </div>
    </Layout>
  );
};

export default ScreensLogin;
