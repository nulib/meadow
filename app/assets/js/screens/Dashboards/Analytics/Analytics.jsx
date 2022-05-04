import React from "react";
import Layout from "@js/screens/Layout";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsAnalytics from "@js/components/Dashboards/Analytics/Analytics";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import IconText from "@js/components/UI/IconText";
import { IconChart } from "@js/components/Icon";
import useGTM from "@js/hooks/useGTM";
import { PageTitle } from "@js/components/UI/UI";

export default function ScreensDashboardsAnalytics() {
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Analytics Dashboard" });
  }, []);

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
          <PageTitle data-testid="page-title">
            <IconText icon={<IconChart />}>
              Digital Collections Analytics
            </IconText>
          </PageTitle>
          <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
            <section className="box">
              <DashboardsAnalytics />
            </section>
          </ErrorBoundary>
        </div>
      </section>
    </Layout>
  );
}
