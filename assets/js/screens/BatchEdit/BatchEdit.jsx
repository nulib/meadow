import React from "react";
import Layout from "../Layout";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import BatchEditPreviewItems from "../../components/BatchEdit/PreviewItems";
import BatchEditTabs from "../../components/BatchEdit/Tabs";
import { mockBatchEditData } from "../../mock-data/batchEditData";
import { useLocation } from "react-router-dom";

export default function BatchEdit() {
  let location = useLocation();
  let items = location.state.items || [];
  let { numberOfResults } = location.state.resultStats || null;

  return (
    <Layout>
      <section className="section" data-testid="batch-edit-screen">
        <div className="container">
          <UIBreadcrumbs
            items={[
              { label: "Search", route: "/search", isActive: false },
              { label: "Batch Edit", route: "/batch-edit", isActive: true },
            ]}
          />
          <div className="box">
            <h1 className="title" data-testid="batch-edit-title">
              Batch Edit
            </h1>

            <p data-testid="num-results">Editing {numberOfResults} rows</p>
            <ul>
              {items.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>

          <div className="box" data-testid="preview-wrapper">
            <BatchEditPreviewItems items={mockBatchEditData} />
          </div>
        </div>
      </section>
      <section className="section">
        <div className="container" data-testid="tabs-wrapper">
          <BatchEditTabs numberOfResults={numberOfResults} />
        </div>
      </section>
    </Layout>
  );
}
