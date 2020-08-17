import React from "react";
import Layout from "../Layout";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import BatchEditPreviewItems from "../../components/BatchEdit/PreviewItems";
import BatchEditTabs from "../../components/BatchEdit/Tabs";
import { mockBatchEditData } from "../../mock-data/batchEditData";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useBatchState } from "../../context/batch-edit-context";

const ScreensBatchEdit = () => {
  const batchState = useBatchState();
  const isActiveSearch = batchState.filteredQuery && batchState.resultStats;

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

            {!isActiveSearch && (
              <div className="notification content">
                <p>
                  <FontAwesomeIcon icon="exclamation-triangle" /> No search
                  results saved in the browsers memory
                </p>
                <p>
                  <Link to="/search" className="button">
                    Search again
                  </Link>
                </p>
              </div>
            )}
          </div>

          {isActiveSearch && (
            <div className="box" data-testid="preview-wrapper">
              <BatchEditPreviewItems items={mockBatchEditData} />
            </div>
          )}
        </div>
      </section>

      {isActiveSearch && (
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
