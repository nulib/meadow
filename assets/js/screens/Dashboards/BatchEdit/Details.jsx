import React from "react";
import Layout from "@js/screens/Layout";
import { useParams } from "react-router-dom";
import UIBreadCrumbs from "@js/components/UI/Breadcrumbs";
import DashboardsBatchEditDetails from "@js/components/Dashboards/BatchEdit/Details";

export default function ScreensDashboardsBatchEditDetails() {
  const params = useParams();

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
                isActive: false,
              },
              {
                label: params.id,
                route: `/dashboards/batch-edit/${params.id}`,
                isActive: true,
              },
            ]}
          />
          <div className="box">
            <h1 className="title" data-testid="page-title">
              Batch Edit Details
            </h1>
            <DashboardsBatchEditDetails id={params.id} />
          </div>
        </div>
      </section>
    </Layout>
  );
}
