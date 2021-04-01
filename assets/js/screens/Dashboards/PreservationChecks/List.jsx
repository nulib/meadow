import React from "react";
import Layout from "@js/screens/Layout";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsPreservationChecksList from "@js/components/Dashboards/PreservationChecks/List";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { IconCheck } from "@js/components/Icon";
import IconText from "@js/components/UI/IconText";

function ScreensDashboardsPreservationChecksList(props) {
  return (
    <Layout>
      <section
        className="section"
        data-testid="dashboard-preservation-checks-screen"
      >
        <div className="container">
          <UIBreadCrumbs
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
          <div className="box">
            <h1
              className="title"
              data-testid="preservation-checks-dashboard-title"
            >
              <IconText icon={<IconCheck />}>
                Preservation Check Dashboard
              </IconText>
            </h1>
            <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
              <DashboardsPreservationChecksList />
            </ErrorBoundary>
          </div>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsPreservationChecksList.propTypes = {};

export default ScreensDashboardsPreservationChecksList;
