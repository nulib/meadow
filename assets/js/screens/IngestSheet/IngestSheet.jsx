import React from "react";
import { withRouter } from "react-router-dom";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import IngestSheet from "../../components/IngestSheet/IngestSheet";
import gql from "graphql-tag";
import { useQuery } from "@apollo/react-hooks";
import {
  INGEST_SHEET_SUBSCRIPTION,
  INGEST_SHEET_QUERY
} from "../../components/IngestSheet/ingestSheet.query";
import Layout from "../Layout";
import {
  getClassFromIngestSheetStatus,
  TEMP_USER_FRIENDLY_STATUS
} from "../../services/helpers";

import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import IngestSheetActionRow from "../../components/IngestSheet/ActionRow";

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
        label: `Projects`,
        route: `/project/list`
      },
      {
        label: `${ingestSheet.project.title}`,
        route: `/project/${id}`
      },
      {
        label: ingestSheet.name,
        route: `/project/${id}/ingest-sheet/${sheetId}`,
        isActive: true
      }
    ];
  };

  return (
    <Layout>
      <section className="hero is-light">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">
              {ingestSheet.name}{" "}
              <span
                className={`tag ${getClassFromIngestSheetStatus(
                  sheetData.ingestSheet.status
                )}`}
              >
                {TEMP_USER_FRIENDLY_STATUS[sheetData.ingestSheet.status]}
              </span>
            </h1>
            <h2 className="subtitle">Ingest Sheet</h2>

            <IngestSheetActionRow
              sheetId={sheetId}
              projectId={id}
              status={sheetData.ingestSheet.status}
              name={sheetData.ingestSheet.name}
            />
          </div>
        </div>
      </section>

      <UIBreadcrumbs items={createCrumbs()} />

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
    </Layout>
  );
};

export default withRouter(ScreensIngestSheet);
