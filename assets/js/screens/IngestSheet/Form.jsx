import React from "react";
import { useParams } from "react-router-dom";
import IngestSheetForm from "../../components/IngestSheet/Form";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import { GET_PROJECT } from "../../components/Project/project.query";
import { useQuery } from "@apollo/react-hooks";
import Layout from "../Layout";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";

const ScreensIngestSheetForm = ({ match }) => {
  const params = useParams();
  const { id } = params;
  const { loading, error, data } = useQuery(GET_PROJECT, {
    variables: { projectId: id }
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const { project } = data;

  return (
    <Layout>
      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column is-8 is-offset-2">
              <UIBreadcrumbs
                items={[
                  { label: "Projects", route: "/project/list" },
                  { label: "Project Name", route: "/" },
                  { label: "Upload Ingest Sheet" }
                ]}
              />
              <div className="box">
                <h1 className="title">Upload a new Ingest Sheet</h1>
                {id && <IngestSheetForm projectId={id} />}
              </div>
            </div>
          </div>
        </div>
      </section>
    </Layout>
  );
};

export default ScreensIngestSheetForm;
