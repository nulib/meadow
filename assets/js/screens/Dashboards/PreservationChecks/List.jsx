import React from "react";
import Layout from "@js/screens/Layout";
import { Breadcrumbs, PageTitle } from "@js/components/UI/UI";
import DashboardsPreservationChecksList from "@js/components/Dashboards/PreservationChecks/List";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { IconCheck } from "@js/components/Icon";
import IconText from "@js/components/UI/IconText";
import useGTM from "@js/hooks/useGTM";

function ScreensDashboardsPreservationChecksList(props) {
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Preservation Checks Dashboard" });
  }, []);

  return (
    <Layout>
      <section
        className="section"
        data-testid="dashboard-preservation-checks-screen"
      >
        <div className="container">
          <Breadcrumbs
            items={[
              {
                label: "Dashboards",
                isActive: false,
              },
              {
                label: "Preservation Checks",
                route: "/dashboards/preservation-checks",
                isActive: true,
              },
            ]}
          />
          <PageTitle data-testid="preservation-checks-dashboard-title">
            <IconText icon={<IconCheck />}>
              Preservation Check Dashboard
            </IconText>
          </PageTitle>
          <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
            <DashboardsPreservationChecksList />
          </ErrorBoundary>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsPreservationChecksList.propTypes = {};

export default ScreensDashboardsPreservationChecksList;
