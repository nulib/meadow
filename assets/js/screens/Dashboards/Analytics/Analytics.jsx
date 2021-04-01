import React from "react";
import Layout from "@js/screens/Layout";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsAnalytics from "@js/components/Dashboards/Analytics/Analytics";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import IconText from "@js/components/UI/IconText";
import { IconChart } from "@js/components/Icon";

export default function ScreensDashboardsAnalytics() {
  return (
    <Layout>
      <section className="section" data-testid="dashboard-analytics-screen">
        <div className="container">
          <UIBreadCrumbs
            items={[
              {
                label: "Dashboards",
                isActive: false,
              },

              {
                label: "Analytics",
                route: `/dashboards/analytics`,
                isActive: true,
              },
            ]}
          />
          <div className="box">
            <h1 className="title" data-testid="page-title">
              <IconText icon={<IconChart />}>
                Digital Collections Analytics
              </IconText>
            </h1>
            <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
              <DashboardsAnalytics />
            </ErrorBoundary>
          </div>
        </div>
      </section>
    </Layout>
  );
}
