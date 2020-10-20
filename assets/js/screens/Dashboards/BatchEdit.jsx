import React from "react";
import PropTypes from "prop-types";
import Layout from "@js/screens/Layout";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsBatchEditTable from "@js/components/Dashboards/BatchEditTable";

function BatchEdit(props) {
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
            <DashboardsBatchEditTable />
          </div>
        </div>
      </section>
    </Layout>
  );
}

BatchEdit.propTypes = {};

export default BatchEdit;
