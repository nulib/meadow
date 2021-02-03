import React from "react";
import Layout from "../Layout";
import CollectionRecentlyUpdated from "@js/components/Collection/RecentlyUpdated";
import WorkForm from "@js/components/Work/WorkForm";
import HomeIngestBox from "@js/components/Home/IngestBox";
import HomeSearchAndSubscribeBox from "@js/components/Home/SearchAndDescribeBox";
import HomeStatsRow from "@js/components/Home/StatsRow";
import MockAreaChart from "@js/components/Home/MockAreaChart";
import MockBarChart from "@js/components/Home/MockBarChart";
import UISkeleton from "@js/components/UI/Skeleton";

const mockStats = [
  {
    heading: "Collections",
    title: 53,
  },
  {
    heading: "Works",
    title: "6,910",
  },
  {
    heading: "Works Published",
    title: "2,044",
  },
];

const ScreensHome = () => {
  const [showWorkForm, setShowWorkForm] = React.useState(false);

  function handleAddWork() {
    setShowWorkForm(!showWorkForm);
  }

  return (
    <Layout>
      <section className="section">
        <div className="container">
          <HomeSearchAndSubscribeBox />
        </div>
      </section>

      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column is-two-thirds">
              <MockAreaChart />
            </div>

            <div className="column is-one-third">
              <HomeIngestBox />
              <HomeStatsRow stats={mockStats} />
            </div>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column">
              <div className="box">
                <h3 className="subtitle is-3">Recently Updated Collections</h3>
                <CollectionRecentlyUpdated />
                <UISkeleton />
              </div>
            </div>
            <div className="column">
              <div className="box">
                <h3 className="subtitle is-3">Visibility</h3>
                <MockBarChart />
              </div>
            </div>
          </div>
        </div>
      </section>
      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column">
              <div className="box">
                <h3 className="subtitle is-3">Google Analytics</h3>
                <UISkeleton />
              </div>
            </div>
            <div className="column">
              <div className="box">
                <h3 className="subtitle is-3">What else?</h3>
                <UISkeleton />
              </div>
            </div>
          </div>
        </div>
      </section>
      <WorkForm showWorkForm={showWorkForm} setShowWorkForm={setShowWorkForm} />
    </Layout>
  );
};

export default ScreensHome;
