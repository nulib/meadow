import React from "react";
import Layout from "@js/screens/Layout";
import { Breadcrumbs } from "@js/components/UI/UI";
import DashboardsProvenanceList from "@js/components/Dashboards/Provenance/List";

export default function ScreensDashboardsProvenanceList() {
  return (
    <Layout>
      <section className="section" data-testid="provenance-list-screen">
        <div className="container">
          <Breadcrumbs
            items={[
              { label: "Dashboards", isActive: false },
              {
                label: "AI Provenance",
                route: "/dashboards/ai-provenance",
                isActive: true,
              },
            ]}
          />
          <h1 className="title">AI Provenance</h1>
          <p className="subtitle is-6 has-text-grey">
            AI-assisted metadata activity across all works.
          </p>
          <DashboardsProvenanceList />
        </div>
      </section>
    </Layout>
  );
}
