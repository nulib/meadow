import React from "react";
import Layout from "../Layout";
import CollectionRecentlyUpdated from "@js/components/Collection/RecentlyUpdated";
import WorkForm from "@js/components/Work/WorkForm";
import HomeIngestBox from "@js/components/Home/IngestBox";
import HomeSearchAndSubscribeBox from "@js/components/Home/SearchAndDescribeBox";
import HomeStatsRow from "@js/components/Home/StatsRow";
import useRepositoryStats from "@js/hooks/useRepositoryStats";
import ChartsRepositoryGrowth from "@js/components/Charts/RepositoryGrowth";
import ChartsVisibility from "@js/components/Charts/Visibility";
import ChartsGoogleAnalytics from "@js/components/Charts/GoogleAnalytics";

const ScreensHome = () => {
  const [showWorkForm, setShowWorkForm] = React.useState(false);
  const { stats = {} } = useRepositoryStats();
  console.log("stats", stats);

  const statsConfig = [
    {
      heading: "Collections",
      title: stats.collections,
    },
    {
      heading: "Works",
      title: stats.works,
    },
    {
      heading: "Works Published",
      title: stats.worksPublished,
    },
  ];

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
              <ChartsRepositoryGrowth
                worksCreatedByWeek={stats.worksCreatedByWeek}
              />
            </div>

            <div className="column is-one-third">
              <HomeIngestBox handleAddWork={handleAddWork} />
              <HomeStatsRow stats={statsConfig} />
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
                <CollectionRecentlyUpdated
                  recentlyUpdatedCollections={stats.collectionsRecentlyUpdated}
                />
              </div>
            </div>
            <div className="column">
              <div className="box">
                <h3 className="subtitle is-3">Visibility</h3>
                <ChartsVisibility data={stats.visibility} />
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
                <ChartsGoogleAnalytics />
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
