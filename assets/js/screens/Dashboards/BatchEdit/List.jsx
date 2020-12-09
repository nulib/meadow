import React from "react";
import Layout from "@js/screens/Layout";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsBatchEditList from "@js/components/Dashboards/BatchEdit/List";

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
              Batch Edit Dashboard
            </h1>
            <DashboardsBatchEditList />
          </div>
        </div>
      </section>
    </Layout>
  );
}

ScreensDashboardsBatchEditList.propTypes = {};

export default ScreensDashboardsBatchEditList;
