import React from "react";
import Error from "../../components/UI/Error";
import IngestSheet from "../../components/IngestSheet/IngestSheet";
import gql from "graphql-tag";
import { useQuery } from "@apollo/client/react";
import { INGEST_SHEET_QUERY } from "../../components/IngestSheet/ingestSheet.gql.js";
import Layout from "../Layout";
import { TEMP_USER_FRIENDLY_STATUS } from "../../services/helpers";
import IngestSheetAlert from "../../components/IngestSheet/Alert";
import IngestSheetActionRow from "../../components/IngestSheet/ActionRow";
import { ErrorBoundary } from "react-error-boundary";
import IngestSheetStatusTag from "@js/components/IngestSheet/StatusTag";
import {
  ActionHeadline,
  Breadcrumbs,
  FallbackErrorComponent,
  PageTitle,
  Skeleton,
} from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";

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
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Ingest Sheet Details" });
  }, []);

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
            <Skeleton rows={2} />
          ) : (
            <Breadcrumbs items={createCrumbs()} />
          )}

          <div className="box">
            {sheetLoading ? (
              <Skeleton rows={5} />
            ) : (
              <>
                <ActionHeadline>
                  <PageTitle>{sheetData.ingestSheet.title}</PageTitle>

                  <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
                    <IngestSheetActionRow
                      sheetId={sheetId}
                      projectId={id}
                      status={sheetData.ingestSheet.status}
                      title={sheetData.ingestSheet.title}
                    />
                  </ErrorBoundary>
                </ActionHeadline>

                <div className="block">
                  <IngestSheetStatusTag status={sheetData.ingestSheet.status}>
                    {TEMP_USER_FRIENDLY_STATUS[sheetData.ingestSheet.status]}
                  </IngestSheetStatusTag>
                </div>

                {["APPROVED", "FILE_FAIL", "ROW_FAIL", "UPLOADED"].indexOf(
                  sheetData.ingestSheet.status
                ) > -1 && (
                  <IngestSheetAlert ingestSheet={sheetData.ingestSheet} />
                )}
              </>
            )}
          </div>
          <div>
            {sheetLoading ? (
              <Skeleton rows={20} />
            ) : (
              <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
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
