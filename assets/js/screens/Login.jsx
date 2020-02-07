import React, { useContext } from "react";
import { AuthContext } from "../components/Auth/Auth";
import { Redirect } from "react-router-dom";
import Layout from "./Layout";

const ScreensLogin = () => {
  const me = useContext(AuthContext);

  if (me) return <Redirect to="/" />;

  return (
    <Layout>
      <section className="hero is-dark">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">Meadow</h1>
            <h2 className="subtitle">
              v 1.0.0 - A new collection management application
            </h2>
          </div>
        </div>
      </section>
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
