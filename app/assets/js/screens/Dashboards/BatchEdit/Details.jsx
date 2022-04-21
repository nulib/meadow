import React from "react";
import Layout from "@js/screens/Layout";
import { useParams } from "react-router-dom";
import { Breadcrumbs, PageTitle } from "@js/components/UI/UI";
import DashboardsBatchEditDetails from "@js/components/Dashboards/BatchEdit/Details";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import useGTM from "@js/hooks/useGTM";

export default function ScreensDashboardsBatchEditDetails() {
  const params = useParams();
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Batch Edit Details" });
  }, []);

  return (
    <Layout>
      <section className="section" data-testid="dashboard-batch-edit-screen">
        <div className="container">
          <Breadcrumbs
            items={[
              {
                label: "Dashboards",
                isActive: false,
              },
              {
                label: "Batch Edit",
                route: "/dashboards/batch-edit",
                isActive: false,
              },
              {
                label: params.id,
                route: `/dashboards/batch-edit/${params.id}`,
                isActive: true,
              },
            ]}
          />
          <PageTitle data-testid="page-title">Batch Edit Details</PageTitle>
          <div className="box">
            <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
              <DashboardsBatchEditDetails id={params.id} />
            </ErrorBoundary>
          </div>
        </div>
      </section>
    </Layout>
  );
}
