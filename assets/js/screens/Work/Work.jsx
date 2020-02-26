import React from "react";
import { useQuery } from "@apollo/react-hooks";
import { GET_WORK } from "../../components/Work/work.query";
import { useParams } from "react-router-dom";
import Layout from "../Layout";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import Work from "../../components/Work/Work";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import ButtonGroup from "../../components/UI/ButtonGroup";

const ScreensWork = () => {
  const { id } = useParams();
  const { data, loading, error } = useQuery(GET_WORK, {
    variables: { id }
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const {
    work: { accessionNumber, published }
  } = data;

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
      label: accessionNumber,
      isActive: true
    }
  ];

  return (
    <Layout>
      <section className="hero is-light" data-testid="work-hero">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">
              {accessionNumber}{" "}
              <span className={`tag ${published ? "is-info" : "is-warning"}`}>
                {published ? "Published" : "Not Published"}
              </span>
            </h1>
            <h2 className="subtitle">Work Accession Number</h2>
            <ButtonGroup>
              {!published && (
                <button
                  className="button is-primary is-outlined"
                  data-testid="publish-button"
                >
                  {!published ? "Publish" : "Unpublish"}
                </button>
              )}
              <button className="button" data-testid="delete-button">
                Delete
              </button>
            </ButtonGroup>
          </div>
        </div>
      </section>
      <UIBreadcrumbs items={breadCrumbs} data-testid="work-breadcrumbs" />
      <Work work={data.work} />
    </Layout>
  );
};

export default ScreensWork;
