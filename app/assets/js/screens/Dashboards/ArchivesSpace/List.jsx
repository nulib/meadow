import React from "react";
import Layout from "@js/screens/Layout";
import DashboardsArchivesSpaceList from "@js/components/Dashboards/ArchivesSpace/List";
import { ErrorBoundary } from "react-error-boundary";
import {
  Breadcrumbs,
  FallbackErrorComponent,
  PageTitle,
} from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";

function ScreensDashboardsArchivesSpaceList() {
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "ArchivesSpace Imports Dashboard" });
  }, []);

  return (
    <Layout>
      <section className="section" data-testid="dashboard-archivesspace-screen">
        <div className="container">
          <Breadcrumbs
            items={[
              {
                label: "Dashboards",
                isActive: false,
              },
              {
                label: "ArchivesSpace Imports",
                route: "/dashboards/archivesspace",
                isActive: true,
              },
            ]}
          />
          <PageTitle>ArchivesSpace Imports</PageTitle>
          <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
            <DashboardsArchivesSpaceList />
          </ErrorBoundary>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsArchivesSpaceList.propTypes = {};

export default ScreensDashboardsArchivesSpaceList;
