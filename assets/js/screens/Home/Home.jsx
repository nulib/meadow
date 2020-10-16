import React, { useContext } from "react";
import { AuthContext } from "../../components/Auth/Auth";
import Layout from "../Layout";
import UIGenericHero from "../../components/UI/GenericHero";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Link } from "react-router-dom";
import Charts from "@js/components/Home/Charts";

const ScreensHome = () => {
  const me = useContext(AuthContext);

  return (
    <Layout>
      <UIGenericHero />
      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column">
              <div className="box has-text-centered content">
                <FontAwesomeIcon icon="file-import" size="4x" />
                <h2 className="title">Ingest Objects</h2>
                <Link className="button" to="/project/list">
                  View Projects
                </Link>
              </div>
            </div>
            <div className="column">
              <div className="box has-text-centered content">
                <FontAwesomeIcon icon="search" size="4x" />
                <h2 className="title">Search &amp; Describe Objects</h2>
                <Link className="button" to="/search">
                  Search All Works
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>
      <section className="section">
        <div className="container">
          <Charts />
        </div>
      </section>
    </Layout>
  );
};

export default ScreensHome;
