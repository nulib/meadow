import React from "react";
import { useQuery } from "@apollo/react-hooks";
import { GET_WORK } from "../../components/Work/work.query";
import { useParams, Link } from "react-router-dom";
import Layout from "../Layout";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import Work from "../../components/Work/Work";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";

const ScreensWork = () => {
  const { id } = useParams();
  const { data, loading, error } = useQuery(GET_WORK, {
    variables: { id }
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const { work } = data;

  const breadCrumbs = [
    {
      label: "Project :: name here",
      route: "/"
    },
    {
      label: "Ingest Sheet :: name here",
      route: "/"
    },
    {
      label: work.accessionNumber,
      isActive: true
    }
  ];

  return (
    <Layout>
      <section className="hero is-light">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">{work.accessionNumber}</h1>
            <h2 className="subtitle">Work Accession Number</h2>
            <Link to="/" className="button is-primary">
              Edit work
            </Link>
          </div>
        </div>
      </section>
      <div className="container">
        <UIBreadcrumbs items={breadCrumbs} />
      </div>
      <Work work={data.work} />
    </Layout>
  );
};

export default ScreensWork;
