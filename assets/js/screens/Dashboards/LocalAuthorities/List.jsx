import React from "react";
import Layout from "@js/screens/Layout";
import DashboardsLocalAuthoritiesList from "@js/components/Dashboards/LocalAuthorities/List";
import DashboardsLocalAuthoritiesTitleBar from "@js/components/Dashboards/LocalAuthorities/TitleBar";
import { ErrorBoundary } from "react-error-boundary";
import { Breadcrumbs, FallbackErrorComponent } from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";

function ScreensDashboardsLocalAuthoritiesList() {
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Local Authorities Dashboard" });
  }, []);

  return (
    <Layout>
      <section
        className="section"
        data-testid="dashboard-local-authorities-screen"
      >
        <div className="container">
          <Breadcrumbs
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
          <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
            <DashboardsLocalAuthoritiesTitleBar />
            <DashboardsLocalAuthoritiesList />
          </ErrorBoundary>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsLocalAuthoritiesList.propTypes = {};

export default ScreensDashboardsLocalAuthoritiesList;
