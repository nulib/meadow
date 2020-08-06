import React from "react";
import Layout from "../Layout";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import BatchEditPreviewItems from "../../components/BatchEdit/PreviewItems";
import BatchEditTabs from "../../components/BatchEdit/Tabs";
import { mockBatchEditData } from "../../mock-data/batchEditData";
import { useLocation } from "react-router-dom";
import JSONPretty from "react-json-pretty";

export default function BatchEdit() {
  let location = useLocation();
  let locationState = location.state;

  // "items" would be an array of Work "id" values
  let items = locationState.items || [];

  // Total number of results from the Elasticsearch query on Search page
  let { numberOfResults } = locationState.resultStats || null;

  // "filteredQuery": Elasticsearch query used to generate results on Search page
  // "parsedAggregations": Object of aggregations for "filteredQuery", holding text values
  // "resultStats": Pulled out of Reactivesearch data
  let { filteredQuery, parsedAggregations, resultStats } = locationState;

  return (
    <Layout>
      <section className="section" data-testid="batch-edit-screen">
        <div className="container">
          <UIBreadcrumbs
            items={[
              {
                label: "Search",
                route: "/search",
                isActive: false,
              },
              {
                label: "Batch Edit",
                route: "/batch-edit",
                isActive: true,
              },
            ]}
          />
          <div className="box">
            <h1 className="title" data-testid="batch-edit-title">
              Batch Edit
            </h1>

            <div className="content">
              <h4>Filtered Elasticsearch Query</h4>
              <JSONPretty data={filteredQuery} />

              <hr />
              <h4>Aggregations to populate Remove items</h4>
              <JSONPretty data={parsedAggregations} />

              <hr />
              <h4>Elasticsearch Query ResultStats</h4>
              <JSONPretty data={resultStats} />

              <hr />
              <p data-testid="num-results">Editing {numberOfResults} rows</p>
              <ul>
                {items.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </div>
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
