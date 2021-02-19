import React from "react";
import Layout from "@js/screens/Layout";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsLocalAuthoritiesList from "@js/components/Dashboards/LocalAuthorities/List";
import DashboardsLocalAuthoritiesTitleBar from "@js/components/Dashboards/LocalAuthorities/TitleBar";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";

function ScreensDashboardsLocalAuthoritiesList() {
  return (
    <Layout>
      <section
        className="section"
        data-testid="dashboard-local-authorities-screen"
      >
        <div className="container">
          <UIBreadCrumbs
            items={[
              {
                label: "Dashboards",
                isActive: false,
              },
              {
                label: "Local Authorities",
                route: "/dashboards/nul-local-authorities",
                isActive: true,
              },
            ]}
          />
          <div className="box">
            <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
              <DashboardsLocalAuthoritiesTitleBar />
              <DashboardsLocalAuthoritiesList />
            </ErrorBoundary>
          </div>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsLocalAuthoritiesList.propTypes = {};

export default ScreensDashboardsLocalAuthoritiesList;
