import React from "react";
import Layout from "@js/screens/Layout";
import DashboardsCsvList from "@js/components/Dashboards/Csv/List";
import DashboardsCsvTitleBar from "@js/components/Dashboards/Csv/TitleBar";
import { ErrorBoundary } from "react-error-boundary";
import { Breadcrumbs, FallbackErrorComponent } from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";

function ScreensDashboardsCsvList() {
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Csv Metadata Export Dashboard" });
  }, []);

  return (
    <Layout>
      <section className="section" data-testid="dashboard-csv-screen">
        <div className="container">
          <Breadcrumbs
            items={[
              {
                label: "Dashboards",
                isActive: false,
              },
              {
                label: "CSV Metadata Update",
                route: "/dashboards/csv-metadata-update",
                isActive: true,
              },
            ]}
          />
          <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
            <DashboardsCsvTitleBar />
            <DashboardsCsvList />
          </ErrorBoundary>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsCsvList.propTypes = {};

export default ScreensDashboardsCsvList;
