import React from "react";
import { useParams } from "react-router-dom";
import IngestSheetForm from "../../components/IngestSheet/Form";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import { GET_PROJECT } from "../../components/Project/project.query";
import { useQuery } from "@apollo/react-hooks";
import Layout from "../Layout";

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
      <section className="hero is-light">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">Upload a new Ingest Sheet</h1>
            <h2 className="subtitle">
              Project: <span className="is-italic">Project title here?</span>
            </h2>
          </div>
        </div>
      </section>
      <section className="section">
        <div className="container">
          {id && <IngestSheetForm projectId={id} />}
        </div>
      </section>
      {/* <ScreenHeader
        title="New Ingest Sheet"
        description="Upload an Ingest sheet here to validate its contents and its work files exist in AWS"
        breadCrumbs={[
          {
            label: "Projects",
            link: "/project/list"
          },
          {
            label: project.title,
            link: `/project/${id}`
          },
          {
            label: "Create ingest sheet",
            link: `/project/${id}/ingest-sheet/upload`
          }
        ]}
      />

      <ScreenContent>{id && <IngestSheetForm projectId={id} />}</ScreenContent> */}
    </Layout>
  );
};

export default ScreensIngestSheetForm;
