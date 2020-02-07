import React from "react";
import { useQuery } from "@apollo/react-hooks";
import { GET_WORKS } from "../../components/Work/work.query";
import Layout from "../Layout";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import WorkListItem from "../../components/Work/ListItem";

const ScreensWorkList = () => {
  const { data, loading, error } = useQuery(GET_WORKS);

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const sampleWorks = data.works.slice(0, 10);

  return (
    <Layout>
      <section className="hero is-light">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">Works</h1>
            <h2 className="subtitle">Every single work in the index</h2>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <p className="notification">[xx] results returned...</p>
          <div className="columns is-multiline">
            {sampleWorks.map(work => (
              <div
                key={work.id}
                className="column is-half-tablet is-one-third-desktop is-one-quarter-widescreen"
              >
                <WorkListItem key={work.id} work={work} />
              </div>
            ))}
          </div>
        </div>
      </section>
    </Layout>
  );
};

export default ScreensWorkList;
