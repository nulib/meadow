import React from "react";
import Layout from "@js/screens/Layout";
import { useParams } from "react-router-dom";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsCsvDetails from "@js/components/Dashboards/Csv/Details";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { GET_CSV_METADATA_UPDATE_JOB } from "@js/components/Dashboards/dashboards.gql";
import { useQuery } from "@apollo/client";
import UISkeleton from "@js/components/UI/Skeleton";

export default function ScreensDashboardsCsvDetails() {
  const params = useParams();

  const { error, loading, data } = useQuery(GET_CSV_METADATA_UPDATE_JOB, {
    variables: {
      id: params.id,
    },
  });

  if (loading) return <UISkeleton />;

  return (
    <Layout>
      <section className="section" data-testid="dashboard-csv-screen">
        <div className="container">
          <UIBreadCrumbs
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
            <h1 className="title" data-testid="page-title">
              CSV Import Details
            </h1>
            {error && (
              <div
                className="notification is-danger is-light"
                data-testid="error-fetching"
              >
                <p>Error fetching batch job id</p>
                <p>{error.toString()}</p>
              </div>
            )}

            {data.csvMetadataUpdateJob && (
              <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
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
