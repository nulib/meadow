import React, { useEffect, useState, Suspense } from "react";
import Layout from "../Layout";
import UIBreadcrumbs from "@js/components/UI/Breadcrumbs";
import UIPreviewItems from "@js/components/UI/PreviewItems";
import BatchEditTabs from "@js/components/BatchEdit/Tabs";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useBatchState } from "@js/context/batch-edit-context";
import { elasticsearchDirectSearch } from "@js/services/elasticsearch";
import UISkeleton from "@js/components/UI/Skeleton";

const ScreensBatchEdit = () => {
  const batchState = useBatchState();
  const isActiveSearch = batchState.filteredQuery && batchState.resultStats;
  const resultsCount = batchState.resultStats
    ? batchState.resultStats.numberOfResults
    : "";

  const [previewItems, setPreviewItems] = useState([]);
  const [isLoadingPreviewItems, setIsLoadingPreviewItems] = useState(true);

  useEffect(() => {
    async function getResultItems() {
      let resultItems = [];
      let results = await elasticsearchDirectSearch({
        size: 25,
        ...batchState.filteredQuery,
      });

      if (results.hits.hits.length > 0) {
        resultItems = results.hits.hits.map((hit) => {
          return {
            id: hit._source.id,
            representativeImage: hit._source.representativeFileSet,
          };
        });
      }
      setIsLoadingPreviewItems(false);
      setPreviewItems(resultItems);
    }
    getResultItems();
  }, []);

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

            {isActiveSearch && (
              <div data-testid="preview-wrapper">
                {isLoadingPreviewItems ? (
                  <UISkeleton rows={5} />
                ) : (
                  <div>
                    <p
                      className="notification is-warning mt-5"
                      data-testid="batch-edit-preview-notification"
                    >
                      <span className="icon">
                        <FontAwesomeIcon icon="exclamation-triangle" />
                      </span>
                      You are batch editing the following {resultsCount} items.
                    </p>
                    <UIPreviewItems items={previewItems} />
                  </div>
                )}
              </div>
            )}

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
