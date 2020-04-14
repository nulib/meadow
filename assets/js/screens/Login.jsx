import React, { useContext } from "react";
import { AuthContext } from "../components/Auth/Auth";
import { Redirect } from "react-router-dom";
import Layout from "./Layout";
import UIGenericHero from "../components/UI/GenericHero";

const ScreensLogin = () => {
  const me = useContext(AuthContext);

  if (me) return <Redirect to="/" />;

  return (
    <Layout>
      <UIGenericHero />
      <div className="section">
        <div className="container has-text-centered">
          <p className="is-size-5 notification is-warning">
            You must be logged in to access Meadow
          </p>
        </div>
      </div>
    </Layout>
  );
};

export default ScreensLogin;
