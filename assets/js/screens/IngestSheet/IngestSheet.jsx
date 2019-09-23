import React from "react";
import { withRouter } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import IngestSheet from "../../components/IngestSheet/IngestSheet";
import gql from "graphql-tag";
import { useQuery } from "@apollo/react-hooks";

const GET_CRUMB_DATA = gql`
  query GetCrumbData($ingestSheetId: String!) {
    ingestSheet(id: $ingestSheetId) {
      name
      project {
        title
      }
    }
  }
`;

const ScreensIngestSheet = ({ match }) => {
  const { id, ingestSheetId } = match.params;
  const { loading, error, data } = useQuery(GET_CRUMB_DATA, {
    variables: { ingestSheetId }
  });

  if (error) return <Error error={error} />;
  if (loading) return <Loading />;

  const { ingestSheet } = data;

  const createCrumbs = () => {
    return [
      {
        label: "Projects",
        link: "/project/list"
      },
      {
        label: ingestSheet.project.title,
        link: `/project/${id}`
      },
      {
        label: ingestSheet.name,
        link: `/project/${id}/ingest-sheet/${ingestSheetId}`
      }
    ];
  };

  return (
    <>
      <ScreenHeader
        title="Ingest Sheet"
        description="The following is system validation/parsing of the .csv Ingest sheet.  Currently it checks 1.) Is it a .csv file?  2.) Are the appropriate headers present?  3.) Do files exist in AWS S3?"
        breadCrumbs={createCrumbs()}
      />
      <ScreenContent>
        <IngestSheet ingestSheetId={ingestSheetId} />
      </ScreenContent>
    </>
  );
};

export default withRouter(ScreensIngestSheet);
export { GET_CRUMB_DATA };
