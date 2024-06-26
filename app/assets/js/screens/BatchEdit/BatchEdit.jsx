import { IconAlert, IconArrowLeft } from "@js/components/Icon";
import React, { useEffect, useState } from "react";

import BatchEditTabs from "@js/components/BatchEdit/Tabs";
import { ErrorBoundary } from "react-error-boundary";
import Layout from "../Layout";
import { Link } from "react-router-dom";
import { Notification } from "@nulib/design-system";
import UIBreadcrumbs from "@js/components/UI/Breadcrumbs";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import UIIconText from "@js/components/UI/IconText";
import UIPreviewItems from "@js/components/UI/PreviewItems";
import UISkeleton from "@js/components/UI/Skeleton";
import UISticky from "@js/components/UI/Sticky";
import { elasticsearchDirectSearch } from "@js/services/elasticsearch";
import { useBatchState } from "@js/context/batch-edit-context";
import useGTM from "@js/hooks/useGTM";

const ScreensBatchEdit = () => {
  const batchState = useBatchState();
  const isActiveSearch = batchState.filteredQuery && batchState.resultStats;
  const resultsCount = batchState.resultStats
    ? batchState.resultStats.numberOfResults
    : "";
  const { loadDataLayer } = useGTM();

  const [previewItems, setPreviewItems] = useState([]);
  const [isLoadingPreviewItems, setIsLoadingPreviewItems] = useState(true);

  useEffect(() => {
    loadDataLayer({
      pageTitle: "Batch Edit",
    });

    async function getResultItems() {
      let resultItems = [];
      let results;

      try {
        results = await elasticsearchDirectSearch({
          size: 25,
          ...batchState.filteredQuery,
        });
        if (results?.hits?.hits?.length > 0) {
          resultItems = results.hits.hits.map((hit) => {
            const { id, representative_file_set, work_type } = hit._source;
            return {
              id: id,
              representativeImage: representative_file_set,
              workTypeId: work_type ? work_type.toUpperCase() : "",
            };
          });
        }
      } catch (error) {
        console.error("error", error);
      }

      setIsLoadingPreviewItems(false);
      setPreviewItems(resultItems);
    }
    getResultItems();
  }, []);

  return (
    <Layout>
      {isActiveSearch && (
        <UISticky>
          <Notification
            isWarning
            className="is-size-5"
            data-testid="batch-edit-preview-notification"
          >
            <UIIconText isCentered icon={<IconAlert />}>
              You are batch editing the following {resultsCount} works.
            </UIIconText>
          </Notification>
        </UISticky>
      )}

      <section
        className="section"
        data-testid="batch-edit-screen"
        style={{ minHeight: "600px" }}
      >
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
            <div className="is-flex is-justify-content-space-between mb-4">
              <h1 className="title" data-testid="batch-edit-title">
                Batch Edit
              </h1>
              {isActiveSearch && (
                <Link
                  data-testid="button-back-to-search"
                  className="button"
                  to={{
                    pathname: "/search",
                    state: { prevQuery: batchState.filteredQuery },
                  }}
                >
                  <span className="icon">
                    <IconArrowLeft />
                  </span>
                  <span>Back to search</span>
                </Link>
              )}
            </div>

            {isActiveSearch && (
              <div data-testid="preview-wrapper">
                {isLoadingPreviewItems ? (
                  <UISkeleton rows={5} />
                ) : (
                  <div>
                    <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
                      <UIPreviewItems items={previewItems} />
                    </ErrorBoundary>
                  </div>
                )}
              </div>
            )}

            {!isActiveSearch && (
              <div className="has-text-centered">
                <Notification className="block">
                  <UIIconText icon={<IconAlert />} isCentered>
                    No search results saved in the browsers memory
                  </UIIconText>
                </Notification>
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
            <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
              <BatchEditTabs />
            </ErrorBoundary>
          </div>
        </section>
      )}
    </Layout>
  );
};

export default ScreensBatchEdit;
