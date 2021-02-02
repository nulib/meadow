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
    title: 12933,
  },
  {
    heading: "Works",
    title: 986324532,
  },
  {
    heading: "Works Published",
    title: 238844,
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
          <HomeStatsRow stats={mockStats} />
        </div>
      </section>
      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column">
              <MockAreaChart />
            </div>

            <div className="column">
              <div className="tile is-ancestor">
                <div className="tile is-parent">
                  <div className="tile box is-child has-text-centered">
                    <HomeIngestBox handleAddWork={handleAddWork} />
                  </div>
                </div>
                <div className="tile is-parent">
                  <div className="tile box is-child has-text-centered">
                    <HomeSearchAndSubscribeBox />
                  </div>
                </div>
              </div>
              {/* <div className="columns">
                <div className="column">
                  <HomeIngestBox handleAddWork={handleAddWork} />
                </div>
                <div className="column">
                  <HomeSearchAndSubscribeBox />
                </div>
              </div> */}
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
