import React from "react";
import Layout from "@js/screens/Layout";
import { Breadcrumbs, PageTitle } from "@js/components/UI/UI";
import DashboardsUsersList from "@js/components/Dashboards/Users/List";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { IconCheck } from "@js/components/Icon";
import IconText from "@js/components/UI/IconText";
import useGTM from "@js/hooks/useGTM";

function ScreensDashboardsUsersList(props) {
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Manage Users Dashboard" });
  }, []);

  return (
    <Layout>
      <section
        className="section"
        data-testid="dashboard-users-screen"
      >
        <div className="container">
          <Breadcrumbs
            items={[
              {
                label: "Dashboards",
                isActive: false,
              },
              {
                label: "Manage Users",
                route: "/dashboards/users",
                isActive: true,
              },
            ]}
          />
          <PageTitle data-testid="users-dashboard-title">
            <IconText icon={<IconCheck />}>
              Manage Users Dashboard
            </IconText>
          </PageTitle>
          <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
            <DashboardsUsersList />
          </ErrorBoundary>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsUsersList.propTypes = {};

export default ScreensDashboardsUsersList;
