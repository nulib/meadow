import React from "react";
import Layout from "../Layout";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import BatchEditPreviewItems from "../../components/BatchEdit/PreviewItems";
import BatchEditTabs from "../../components/BatchEdit/Tabs";

export default function BatchEdit() {
  return (
    <Layout>
      <section className="section">
        <div className="container">
          <UIBreadcrumbs
            items={[
              { label: "Batch Edit", route: "/batch-edit", isActive: true },
            ]}
          />
          <div className="box">
            <h1 className="title" data-testid="title">
              Batch Edit
            </h1>
            <p data-testid="num-results">Editing 50 rows</p>
          </div>

          <div className="box" data-testid="preview-wrapper">
            <BatchEditPreviewItems />
          </div>

          <div className="box" data-testid="tabs-wrapper">
            <BatchEditTabs />
          </div>
        </div>
      </section>
    </Layout>
  );
}
