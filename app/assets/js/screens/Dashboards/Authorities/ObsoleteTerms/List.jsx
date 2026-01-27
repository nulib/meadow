import React from "react";
import Layout from "@js/screens/Layout";
import DashboardsObsoleteTermsList from "@/js/components/Dashboards/Authorities/ObsoleteTerms/List";
import DashboardsObsoleteTermsTitleBar from "@/js/components/Dashboards/Authorities/ObsoleteTerms/TitleBar"; "@js/components/Dashboards/ObsoleteTerms/TitleBar";
import { ErrorBoundary } from "react-error-boundary";
import { Breadcrumbs, FallbackErrorComponent } from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";

function ScreensDashboardsObsoleteTermsList() {
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Obsolete Controlled Terms Dashboard" });
  }, []);

  return (
    <Layout>
      <section
        className="section"
        data-testid="dashboard-obsolete-terms-screen"
      >
        <div className="container">
          <Breadcrumbs
            items={[
              {
                label: "Dashboards",
                isActive: false,
              },
              {
                label: "Obsolete Controlled Terms",
                route: "/dashboards/obsolete-terms",
                isActive: true,
              },
            ]}
          />
          <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
            <DashboardsObsoleteTermsTitleBar />
            <DashboardsObsoleteTermsList />
          </ErrorBoundary>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsObsoleteTermsList.propTypes = {};

export default ScreensDashboardsObsoleteTermsList;
