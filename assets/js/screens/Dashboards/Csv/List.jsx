import React from "react";
import Layout from "@js/screens/Layout";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsCsvList from "@js/components/Dashboards/Csv/List";
import DashboardsCsvTitleBar from "@js/components/Dashboards/Csv/TitleBar";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";

function ScreensDashboardsCsvList() {
  return (
    <Layout>
      <section className="section" data-testid="dashboard-csv-screen">
        <div className="container">
          <UIBreadCrumbs
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
          <div className="box">
            <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
              <DashboardsCsvTitleBar />
              <DashboardsCsvList />
            </ErrorBoundary>
          </div>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsCsvList.propTypes = {};

export default ScreensDashboardsCsvList;
