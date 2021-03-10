import React from "react";
import Layout from "@js/screens/Layout";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsBatchEditList from "@js/components/Dashboards/BatchEdit/List";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { GrMultiple } from "react-icons/gr";
import IconText from "@js/components/UI/IconText";

function ScreensDashboardsBatchEditList(props) {
  return (
    <Layout>
      <section className="section" data-testid="dashboard-batch-edit-screen">
        <div className="container">
          <UIBreadCrumbs
            items={[
              {
                label: "Dashboards",
                isActive: false,
              },
              {
                label: "Batch Edit",
                route: "/dashboards/batch-edit",
                isActive: true,
              },
            ]}
          />
          <div className="box">
            <h1 className="title" data-testid="batch-edit-dashboard-title">
              <IconText icon={<GrMultiple />}>Batch Edit Dashboard</IconText>
            </h1>
            <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
              <DashboardsBatchEditList />
            </ErrorBoundary>
          </div>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsBatchEditList.propTypes = {};

export default ScreensDashboardsBatchEditList;
