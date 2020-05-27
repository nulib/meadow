import React from "react";
import Error from "../../components/UI/Error";
import UILoadingPage from "../../components/UI/LoadingPage";
import UILoading from "../../components/UI/Loading";
import UISkeleton from "../../components/UI/Skeleton";
import IngestSheet from "../../components/IngestSheet/IngestSheet";
import gql from "graphql-tag";
import { useQuery } from "@apollo/react-hooks";
import {
  INGEST_SHEET_SUBSCRIPTION,
  INGEST_SHEET_QUERY,
} from "../../components/IngestSheet/ingestSheet.gql.js";
import Layout from "../Layout";
import {
  getClassFromIngestSheetStatus,
  TEMP_USER_FRIENDLY_STATUS,
} from "../../services/helpers";
import IngestSheetAlert from "../../components/IngestSheet/Alert";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import IngestSheetActionRow from "../../components/IngestSheet/ActionRow";

const GET_CRUMB_DATA = gql`
  query GetCrumbData($sheetId: ID!) {
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
    data: crumbsData,
  } = useQuery(GET_CRUMB_DATA, {
    variables: { sheetId },
  });

  const {
    subscribeToMore,
    data: sheetData,
    loading: sheetLoading,
    error: sheetError,
  } = useQuery(INGEST_SHEET_QUERY, {
    variables: { sheetId },
    fetchPolicy: "network-only",
  });

  if (crumbsError || sheetError)
    return <Error error={crumbsError ? crumbsError : sheetError} />;

  const createCrumbs = () => {
    return [
      {
        label: `Projects`,
        route: `/project/list`,
      },
      {
        label: `${crumbsData.ingestSheet.project.title}`,
        route: `/project/${id}`,
      },
      {
        label: "Ingest Sheets",
        route: `/project/${id}`,
      },
      {
        label: crumbsData.ingestSheet.name,
        route: `/project/${id}/ingest-sheet/${sheetId}`,
        isActive: true,
      },
    ];
  };

  return (
    <Layout>
      <section className="section">
        <div className="container">
          {crumbsLoading ? (
            <UISkeleton rows={2} />
          ) : (
            <UIBreadcrumbs items={createCrumbs()} />
          )}

          <div className="box">
            {sheetLoading ? (
              <UISkeleton rows={5} />
            ) : (
              <>
                <div className="columns">
                  <div className="column is-half">
                    <h1 className="title">
                      {sheetData.ingestSheet.name}{" "}
                      <span
                        className={`tag ${getClassFromIngestSheetStatus(
                          sheetData.ingestSheet.status
                        )}`}
                      >
                        {
                          TEMP_USER_FRIENDLY_STATUS[
                            sheetData.ingestSheet.status
                          ]
                        }
                      </span>
                    </h1>
                    <h2 className="subtitle">Ingest Sheet</h2>
                  </div>
                  <div className="column is-half">
                    <IngestSheetActionRow
                      sheetId={sheetId}
                      projectId={id}
                      status={sheetData.ingestSheet.status}
                      name={sheetData.ingestSheet.name}
                    />
                  </div>
                </div>

                {[
                  "APPROVED",
                  "FILE_FAIL",
                  "ROW_FAIL",
                  "UPLOADED",
                  "VALID",
                ].indexOf(sheetData.ingestSheet.status) > -1 && (
                  <IngestSheetAlert ingestSheet={sheetData.ingestSheet} />
                )}
              </>
            )}
          </div>

          {sheetLoading ? (
            <UISkeleton rows={20} />
          ) : (
            <IngestSheet
              ingestSheetData={sheetData.ingestSheet}
              projectId={id}
              subscribeToIngestSheetUpdates={() =>
                subscribeToMore({
                  document: INGEST_SHEET_SUBSCRIPTION,
                  variables: { sheetId },
                  updateQuery: (prev, { subscriptionData }) => {
                    if (!subscriptionData.data) return prev;
                    const updatedSheet =
                      subscriptionData.data.ingestSheetUpdate;
                    return { ingestSheet: { ...updatedSheet } };
                  },
                })
              }
            />
          )}
        </div>
      </section>
    </Layout>
  );
};

export default ScreensIngestSheet;
