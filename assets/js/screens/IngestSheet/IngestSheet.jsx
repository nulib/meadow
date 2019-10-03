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
  const {
    loading: crumbsLoading,
    error: crumbsError,
    data: crumbsData
  } = useQuery(GET_CRUMB_DATA, {
    variables: { ingestSheetId }
  });

  const {
    subscribeToMore,
    data: sheetData,
    loading: sheetLoading,
    error: sheetError
  } = useQuery(INGEST_SHEET_QUERY, {
    variables: { ingestSheetId }
  });

  if (crumbsLoading || sheetLoading) return <Loading />;
  if (crumbsError || sheetError)
    return <Error error={crumbsError || sheetError} />;

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
        <div className="p-4 bg-yellow-100 text-sm">
          <p className="text-gray-600">
            Temporary subnavigation for further Ingest Sheet status
          </p>
          <Link
            to={`/project/${id}/ingest-sheet/${ingestSheetId}/approved-in-progress`}
          >
            Approved: building works
          </Link>
          <Link
            to={`/project/${id}/ingest-sheet/${ingestSheetId}/approved`}
            className="pl-4"
          >
            Approved: works created
          </Link>
        </div>

        <IngestSheet
          ingestSheetData={sheetData.ingestSheet}
          subscribeToIngestSheetUpdates={() =>
            subscribeToMore({
              document: INGEST_SHEET_SUBSCRIPTION,
              variables: { ingestSheetId },
              updateQuery: (prev, { subscriptionData }) => {
                console.log(
                  "TCL: ScreensIngestSheet -> subscriptionData",
                  subscriptionData
                );
                console.log("TCL: ScreensIngestSheet -> prev", prev);
                if (!subscriptionData.data) return prev;
                const updatedSheet = subscriptionData.data.ingestSheet;

                // Note we'll have to see how this really works... it happens so fast now, that this code block
                // isn't running.  It might have to be a 5000 row Ingest Sheet or something...
                return Object.assign({}, prev, {
                  updatedSheet
                });
              }
            })
          }
        />
      </ScreenContent>
    </>
  );
};

export default withRouter(ScreensIngestSheet);
