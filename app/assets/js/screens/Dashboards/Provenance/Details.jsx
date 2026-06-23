import React from "react";
import { useParams } from "react-router-dom";
import Layout from "@js/screens/Layout";
import { Breadcrumbs } from "@js/components/UI/UI";
import DashboardsProvenanceDetails from "@js/components/Dashboards/Provenance/Details";

export default function ScreensDashboardsProvenanceDetails() {
  const { id } = useParams();

  return (
    <Layout>
      <section className="section" data-testid="provenance-details-screen">
        <div className="container">
          <Breadcrumbs
            items={[
              { label: "Dashboards", isActive: false },
              {
                label: "AI Provenance",
                route: "/dashboards/ai-provenance",
                isActive: false,
              },
              {
                label: "Activity",
                route: `/dashboards/ai-provenance/${id}`,
                isActive: true,
              },
            ]}
          />
          <h1 className="title">AI Activity</h1>
          <DashboardsProvenanceDetails id={id} />
        </div>
      </section>
    </Layout>
  );
}
