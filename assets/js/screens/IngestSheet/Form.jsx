import React from "react";
import { withRouter } from "react-router-dom";
import IngestSheetForm from "../../components/IngestSheet/Form";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import { GET_PROJECT } from "../Project/Project";
import { useQuery } from "@apollo/react-hooks";

const ScreensIngestSheetForm = ({ match }) => {
  const { id } = match.params;
  const { loading, error, data } = useQuery(GET_PROJECT, {
    variables: { projectId: id }
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const { project } = data;

  return (
    <>
      <ScreenHeader
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

      <ScreenContent>{id && <IngestSheetForm projectId={id} />}</ScreenContent>
    </>
  );
};

export default withRouter(ScreensIngestSheetForm);
export { GET_PROJECT };
