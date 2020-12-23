import React from "react";
import Layout from "@js/screens/Layout";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsLocalAuthoritiesList from "@js/components/Dashboards/LocalAuthorities/List";
import DashboardsLocalAuthoritiesTitleBar from "@js/components/Dashboards/LocalAuthorities/TitleBar";
import { ErrorBoundary } from "react-error-boundary";

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
            <ErrorBoundary FallbackComponent={ErrorFallback}>
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

function ErrorFallback({ error }) {
  return (
    <div role="alert" className="notification is-danger">
      <p>There was an error rendering</p>
      <p>
        <strong>Error</strong>: {error.message}
      </p>
    </div>
  );
}
