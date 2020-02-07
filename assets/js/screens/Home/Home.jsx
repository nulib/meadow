import React, { useContext } from "react";
import { AuthContext } from "../../components/Auth/Auth";
import Layout from "../Layout";

const ScreensHome = () => {
  const me = useContext(AuthContext);

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
        <div className="container">
          <p>Home screen content here</p>
        </div>
      </div>
    </Layout>
  );
};

export default ScreensHome;
