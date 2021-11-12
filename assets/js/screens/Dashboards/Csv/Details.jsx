import React from "react";
import Layout from "@js/screens/Layout";
import { useParams } from "react-router-dom";
import DashboardsCsvDetails from "@js/components/Dashboards/Csv/Details";
import { ErrorBoundary } from "react-error-boundary";
import { GET_CSV_METADATA_UPDATE_JOB } from "@js/components/Dashboards/dashboards.gql";
import { useQuery } from "@apollo/client";
import {
  Breadcrumbs,
  FallbackErrorComponent,
  PageTitle,
  Skeleton,
} from "@js/components/UI/UI";
import { Notification } from "@nulib/design-system";
import useGTM from "@js/hooks/useGTM";

export default function ScreensDashboardsCsvDetails() {
  const params = useParams();
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Csv Metadata Export Details" });
  }, []);

  const { error, loading, data } = useQuery(GET_CSV_METADATA_UPDATE_JOB, {
    variables: {
      id: params.id,
    },
  });

  if (loading) return <Skeleton />;

  return (
    <Layout>
      <section className="section" data-testid="dashboard-csv-screen">
        <div className="container">
          <Breadcrumbs
            items={[
              {
                label: "Dashboards",
                isActive: false,
              },
              {
                label: "CSV Metadata Update",
                route: "/dashboards/csv-metadata-update",
                isActive: false,
              },
              {
                label: params.id,
                route: `/dashboards/csv/${params.id}`,
                isActive: true,
              },
            ]}
          />
          <div className="box">
            <PageTitle data-testid="page-title">CSV Import Details</PageTitle>

            {error && (
              <Notification isDanger data-testid="error-fetching">
                <p>Error fetching batch job id</p>
                <p>{error.toString()}</p>
              </Notification>
            )}

            {data.csvMetadataUpdateJob && (
              <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
                <DashboardsCsvDetails
                  csvMetadataUpdateJob={data.csvMetadataUpdateJob}
                />
              </ErrorBoundary>
            )}
          </div>
        </div>
      </section>
    </Layout>
  );
}
