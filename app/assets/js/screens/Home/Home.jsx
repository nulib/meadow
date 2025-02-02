import CalloutActionsRow from "@js/components/Home/CalloutActionsRow";
import ChartsGoogleAnalytics from "@js/components/Charts/GoogleAnalytics";
import ChartsRepositoryGrowth from "@js/components/Charts/RepositoryGrowth";
import ChartsVisibility from "@js/components/Charts/Visibility";
import CollectionRecentlyUpdated from "@js/components/Collection/RecentlyUpdated";
import HomeIngestBox from "@js/components/Home/IngestBox";
import HomeStatsRow from "@js/components/Home/StatsRow";
import Layout from "../Layout";
import { Link } from "react-router-dom";
import React from "react";
import WorkForm from "@js/components/Work/WorkForm";
import useGTM from "@js/hooks/useGTM";
import useRepositoryStats from "@js/hooks/useRepositoryStats";

const ScreensHome = () => {
  const [showWorkForm, setShowWorkForm] = React.useState(false);
  const { stats = {} } = useRepositoryStats();
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Home" });
  }, []);

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
      heading: "File Sets",
      title: stats.fileSets,
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
      {/* <HomeSearchAndSubscribeBox /> */}
      <CalloutActionsRow handleAddWork={handleAddWork} />

      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column is-two-thirds">
              <ChartsRepositoryGrowth
                worksCreatedByWeek={stats.worksCreatedByWeek}
                fileSetsCreatedByWeek={stats.fileSetsCreatedByWeek}
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
                <ChartsGoogleAnalytics />
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
                <h3 className="subtitle is-3">Recently Updated Collections</h3>

                <div className="block">
                  <CollectionRecentlyUpdated
                    recentlyUpdatedCollections={
                      stats.collectionsRecentlyUpdated
                    }
                  />
                </div>
                <Link to="/collection/list" className="button">
                  View all collections
                </Link>
              </div>
            </div>
            <div className="column">
              <div className="box">
                <h3 className="subtitle is-3">Works Visibility</h3>
                <ChartsVisibility data={stats.visibility} />
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
