import React from "react";
import Layout from "../Layout";
import UIGenericHero from "../../components/UI/GenericHero";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Link } from "react-router-dom";
import Charts from "@js/components/Home/Charts";
import { Button } from "@nulib/admin-react-components";
import WorkForm from "@js/components/Work/WorkForm";

const ScreensHome = () => {
  const [showWorkForm, setShowWorkForm] = React.useState(false);

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
                <div className="buttons is-centered">
                  <Link className="button" to="/project/list">
                    View Projects
                  </Link>
                  <Button
                    data-testid="add-work-button"
                    onClick={() => setShowWorkForm(!showWorkForm)}
                  >
                    Add Work
                  </Button>
                </div>
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
      <WorkForm showWorkForm={showWorkForm} setShowWorkForm={setShowWorkForm} />
    </Layout>
  );
};

export default ScreensHome;
