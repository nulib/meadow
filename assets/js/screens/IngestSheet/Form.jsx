import React from "react";
import { useParams } from "react-router-dom";
import IngestSheetForm from "../../components/IngestSheet/Form";
import Error from "../../components/UI/Error";
import UISkeleton from "@js/components/UI/Skeleton";
import { GET_PROJECT } from "../../components/Project/project.gql.js";
import { useQuery } from "@apollo/client";
import Layout from "../Layout";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";

const ScreensIngestSheetForm = ({ match }) => {
  const params = useParams();
  const { id } = params;
  const { loading, error, data } = useQuery(GET_PROJECT, {
    variables: { projectId: id },
  });

  if (error) return <Error error={error} />;

  return (
    <Layout>
      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column is-8 is-offset-2">
              {loading ? (
                <UISkeleton />
              ) : (
                <>
                  <UIBreadcrumbs
                    items={[
                      { label: "Projects", route: "/project/list" },
                      {
                        label: data.project.title,
                        route: `/project/${data.project.id}`,
                      },
                      { label: "Upload Ingest Sheet" },
                    ]}
                  />
                  <div className="box">
                    <h1 className="title">Upload a new Ingest Sheet</h1>
                    {id && <IngestSheetForm project={data.project} />}
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      </section>
    </Layout>
  );
};

export default ScreensIngestSheetForm;
