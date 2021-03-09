import React from "react";
import Error from "../../components/UI/Error";
import UISkeleton from "../../components/UI/Skeleton";
import IngestSheet from "../../components/IngestSheet/IngestSheet";
import gql from "graphql-tag";
import { useQuery } from "@apollo/client";
import { INGEST_SHEET_QUERY } from "../../components/IngestSheet/ingestSheet.gql.js";
import Layout from "../Layout";
import { TEMP_USER_FRIENDLY_STATUS } from "../../services/helpers";
import IngestSheetAlert from "../../components/IngestSheet/Alert";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import IngestSheetActionRow from "../../components/IngestSheet/ActionRow";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { Tag } from "@nulib/admin-react-components";
import IngestSheetStatusTag from "@js/components/IngestSheet/StatusTag";

const GET_CRUMB_DATA = gql`
  query GetCrumbData($sheetId: ID!) {
    ingestSheet(id: $sheetId) {
      id
      title
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
    data: sheetData,
    loading: sheetLoading,
    error: sheetError,
    subscribeToMore: sheetSubscribeToMore,
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
        label: crumbsData.ingestSheet.title,
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
                <div className="is-flex is-justify-content-space-between mb-3">
                  <div>
                    <h1 className="title">{sheetData.ingestSheet.title} </h1>
                    <IngestSheetStatusTag status={sheetData.ingestSheet.status}>
                      {TEMP_USER_FRIENDLY_STATUS[sheetData.ingestSheet.status]}
                    </IngestSheetStatusTag>
                  </div>
                  <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
                    <IngestSheetActionRow
                      sheetId={sheetId}
                      projectId={id}
                      status={sheetData.ingestSheet.status}
                      title={sheetData.ingestSheet.title}
                    />
                  </ErrorBoundary>
                </div>

                {["APPROVED", "FILE_FAIL", "ROW_FAIL", "UPLOADED"].indexOf(
                  sheetData.ingestSheet.status
                ) > -1 && (
                  <IngestSheetAlert ingestSheet={sheetData.ingestSheet} />
                )}
              </>
            )}

            {sheetLoading ? (
              <UISkeleton rows={20} />
            ) : (
              <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
                <IngestSheet
                  ingestSheetData={sheetData.ingestSheet}
                  projectId={id}
                  subscribeToIngestSheetUpdates={sheetSubscribeToMore}
                />
              </ErrorBoundary>
            )}
          </div>
        </div>
      </section>
    </Layout>
  );
};

export default ScreensIngestSheet;
