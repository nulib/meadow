import React from "react";
import { withRouter } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import IngestSheet from "../../components/IngestSheet/IngestSheet";
import gql from "graphql-tag";
import { useQuery } from "@apollo/react-hooks";
import { Link } from "react-router-dom";
import {
  INGEST_SHEET_SUBSCRIPTION,
  INGEST_SHEET_QUERY
} from "../../components/IngestSheet/ingestSheet.query";

const GET_CRUMB_DATA = gql`
  query GetCrumbData($sheetId: String!) {
    ingestSheet(id: $sheetId) {
      id
      name
      project {
        id
        title
      }
    }
  }
`;

const ScreensIngestSheet = ({ match }) => {
  const { id, sheetId } = match.params;
  const {
    loading: crumbsLoading,
    error: crumbsError,
    data: crumbsData
  } = useQuery(GET_CRUMB_DATA, {
    variables: { sheetId }
  });

  const {
    subscribeToMore,
    data: sheetData,
    loading: sheetLoading,
    error: sheetError
  } = useQuery(INGEST_SHEET_QUERY, {
    variables: { sheetId },
    fetchPolicy: "network-only"
  });

  if (crumbsLoading || sheetLoading) return <Loading />;
  if (crumbsError || sheetError)
    return <Error error={crumbsError ? crumbsError : sheetError} />;

  const { ingestSheet } = crumbsData;

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
        link: `/project/${id}/ingest-sheet/${sheetId}`,
        labelWithoutLink: "Sheet:"
      }
    ];
  };

  return (
    <>
      <ScreenHeader
        title="Ingest Sheet"
        description="Feedback on the current status of an Ingest Sheet .csv file moving into the system."
        breadCrumbs={createCrumbs()}
      />
      <ScreenContent>
        <IngestSheet
          ingestSheetData={sheetData.ingestSheet}
          projectId={id}
          subscribeToIngestSheetUpdates={() =>
            subscribeToMore({
              document: INGEST_SHEET_SUBSCRIPTION,
              variables: { sheetId },
              updateQuery: (prev, { subscriptionData }) => {
                if (!subscriptionData.data) return prev;
                const updatedSheet = subscriptionData.data.ingestSheetUpdate;
                return { ingestSheet: { ...updatedSheet } };
              }
            })
          }
        />
      </ScreenContent>
    </>
  );
};

export default withRouter(ScreensIngestSheet);
