import React from "react";
import Layout from "@js/screens/Layout";
import DashboardsBatchEditList from "@js/components/Dashboards/BatchEdit/List";
import { ErrorBoundary } from "react-error-boundary";
import { GrMultiple } from "react-icons/gr";
import IconText from "@js/components/UI/IconText";
import {
  Breadcrumbs,
  FallbackErrorComponent,
  PageTitle,
} from "@js/components/UI/UI";

function ScreensDashboardsBatchEditList(props) {
  return (
    <Layout>
      <section className="section" data-testid="dashboard-batch-edit-screen">
        <div className="container">
          <Breadcrumbs
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
            <PageTitle data-testid="batch-edit-dashboard-title">
              <IconText icon={<GrMultiple />}>Batch Edit Dashboard</IconText>
            </PageTitle>
            <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
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
