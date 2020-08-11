import React from "react";
import Layout from "../Layout";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import BatchEditPreviewItems from "../../components/BatchEdit/PreviewItems";
import BatchEditTabs from "../../components/BatchEdit/Tabs";
import { mockBatchEditData } from "../../mock-data/batchEditData";
import { useLocation, Link } from "react-router-dom";
import JSONPretty from "react-json-pretty";

const ScreensBatchEdit = () => {
  let location = useLocation();
  let locationState = location.state;

  // "filteredQuery": Elasticsearch query used to generate results on Search page
  // "parsedAggregations": Object of aggregations for "filteredQuery", holding text values
  // "resultStats": Pulled out of Reactivesearch data
  let filteredQuery = locationState ? locationState.filteredQuery : null;
  let parsedAggregations = locationState
    ? locationState.parsedAggregations
    : null;
  let resultStats = locationState ? locationState.resultStats : null;

  // "items" would be an array of Work "id" values
  let items = locationState && locationState.items ? locationState.items : [];

  // Total number of results from the Elasticsearch query on Search page
  let numberOfResults = locationState
    ? locationState.resultStats.numberOfResults
    : null;

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

            {!locationState && (
              <div className="notification is-danger is-light content">
                <p>No search results saved in the browsers memory</p>
                <p>
                  <Link to="/search">Search again</Link>
                </p>
              </div>
            )}

            {/* {locationState && (
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
            )} */}
          </div>

          {locationState && (
            <div className="box" data-testid="preview-wrapper">
              <BatchEditPreviewItems items={mockBatchEditData} />
            </div>
          )}
        </div>
      </section>

      {locationState && (
        <section className="section">
          <div className="container" data-testid="tabs-wrapper">
            <BatchEditTabs />
          </div>
        </section>
      )}
    </Layout>
  );
};

export default ScreensBatchEdit;
