import React from "react";
import Layout from "../Layout";
import UIGenericHero from "@js/components/UI/GenericHero";
import Charts from "@js/components/Home/Charts";
import WorkForm from "@js/components/Work/WorkForm";
import HomeIngestBox from "@js/components/Home/IngestBox";
import HomeSearchAndSubscribeBox from "@js/components/Home/SearchAndDescribeBox";

const ScreensHome = () => {
  const [showWorkForm, setShowWorkForm] = React.useState(false);

  function handleAddWork() {
    setShowWorkForm(!showWorkForm);
  }

  return (
    <Layout>
      <UIGenericHero />
      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column">
              <HomeIngestBox handleAddWork={handleAddWork} />
            </div>
            <div className="column">
              <HomeSearchAndSubscribeBox />
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
