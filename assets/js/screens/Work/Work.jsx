import React, { useState } from "react";
import { useMutation, useQuery } from "@apollo/client";
import {
  CREATE_SHARED_LINK,
  GET_WORK,
  UPDATE_WORK,
} from "../../components/Work/work.gql.js";
import { useHistory, useParams } from "react-router-dom";
import Layout from "../Layout";
import UISkeleton from "../../components/UI/Skeleton";
import Work from "../../components/Work/Work";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import { toastWrapper } from "../../services/helpers";
import { Link } from "react-router-dom";
import WorkTagsList from "../../components/Work/TagsList";
import WorkHeaderButtons from "../../components/Work/HeaderButtons";
import WorkSharedLinkNotification from "../../components/Work/SharedLinkNotification";
import WorkPublicLinkNotification from "../../components/Work/PublicLinkNotification";
import WorkMultiEditBar from "../../components/Work/MultiEditBar";
import { useBatchState } from "../../context/batch-edit-context";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { Button } from "@nulib/admin-react-components";

const ScreensWork = () => {
  const params = useParams();
  const { id } = params;
  const history = useHistory();
  const batchState = useBatchState();
  const [isWorkOpen, setIsWorkOpen] = useState(false);

  const multiCurrentIndex = params.counter
    ? parseInt(params.counter.split(",")[0])
    : null;
  const multiTotalItems = params.counter
    ? parseInt(params.counter.split(",")[1])
    : null;

  const { data, loading, error } = useQuery(GET_WORK, {
    variables: { id },
    onError() {
      history.push("/404", {
        message:
          "There was an error retrieving the work, or the work id does not exist.",
      });
    },
  });

  const [updateWork] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      toastWrapper(
        "is-success",
        `Work has been ${updateWork.published ? "published" : "unpublished"}`
      );
    },
  });

  const [createSharedLink, { data: createSharedLinkData }] = useMutation(
    CREATE_SHARED_LINK
  );

  if (error) {
    return null;
  }

  const handleCreateSharableBtnClick = () => {
    const isPublished = data.work.published;
    const isPublic = data.work.visibility
      ? data.work.visibility.id === "OPEN"
      : false;

    if (isPublished && isPublic) {
      setIsWorkOpen(true);
    } else {
      createSharedLink({
        variables: {
          workId: id,
        },
      });
    }
  };

  const handleMultiNavClick = (nextWorkIndex) => {
    history.push(
      `/work/${batchState.editAndViewWorks[nextWorkIndex]}/multi/${nextWorkIndex},${multiTotalItems}`
    );
  };

  const isMulti = () => {
    if (!params.multi) {
      return false;
    }
    return (
      multiCurrentIndex > -1 &&
      multiTotalItems &&
      batchState.editAndViewWorks.length > 0
    );
  };

  const breadCrumbs = [
    {
      label: `Search Works`,
      route: `/search`,
    },
    {
      label: "Work",
      isActive: true,
    },
  ];

  const handlePublishClick = () => {
    let workUpdateInput = {
      published: !data.work.published,
    };

    updateWork({
      variables: { id, work: workUpdateInput },
    });
  };

  const handleFacetLinkClick = (facet, value) => {
    history.push("/search", {
      externalFacet: {
        facetComponentId: facet,
        value: value,
      },
    });
  };

  return (
    <Layout>
      <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
        <section className="section" data-testid="work-hero">
          <div className="container">
            <UIBreadcrumbs items={breadCrumbs} data-testid="work-breadcrumbs" />

            {isMulti() && (
              <WorkMultiEditBar
                currentIndex={multiCurrentIndex}
                handleMultiNavClick={handleMultiNavClick}
                totalItems={multiTotalItems}
              />
            )}

            <div className="box">
              {loading ? (
                <UISkeleton rows={5} />
              ) : (
                <>
                  <div className="columns">
                    <div className="column">
                      <h1 className="title">
                        {data.work.descriptiveMetadata.title || "Untitled"}{" "}
                      </h1>
                      <WorkTagsList work={data.work} />
                    </div>
                    <div className="column">
                      <WorkHeaderButtons
                        handleCreateSharableBtnClick={
                          handleCreateSharableBtnClick
                        }
                        handlePublishClick={handlePublishClick}
                        published={data.work.published}
                        hasCollection={data.work.collection ? true : false}
                      />
                    </div>
                  </div>

                  <div className="content">
                    {createSharedLinkData && (
                      <WorkSharedLinkNotification
                        linkData={createSharedLinkData.createSharedLink}
                      />
                    )}
                    {isWorkOpen && (
                      <WorkPublicLinkNotification workId={data.work.id} />
                    )}

                    <hr />
                    <div className="columns">
                      <div className="column">
                        <p>
                          <strong>Accession Number</strong>
                        </p>
                        <p>{data.work.accessionNumber}</p>
                      </div>
                      <div className="column">
                        <p>
                          <strong>Project</strong>
                        </p>
                        {data.work.project &&
                          data.work.project.id &&
                          data.work.project.title && (
                            <p>
                              <Button
                                isText
                                onClick={() =>
                                  handleFacetLinkClick(
                                    "Project",
                                    data.work.project.title
                                  )
                                }
                                data-testid="view-project-works"
                              >
                                {data.work.project.title}
                              </Button>
                            </p>
                          )}
                      </div>
                      <div className="column">
                        <p>
                          <strong>Ingest Sheet</strong>
                        </p>
                        <p>
                          {data.work.project && data.work.ingestSheet && (
                            <Button
                              isText
                              onClick={() =>
                                handleFacetLinkClick(
                                  "IngestSheet",
                                  data.work.ingestSheet.title
                                )
                              }
                              data-testid="view-ingest-sheet-works"
                            >
                              {data.work.ingestSheet.title}
                            </Button>
                          )}
                        </p>
                      </div>
                    </div>
                  </div>
                </>
              )}
            </div>
          </div>
        </section>
      </ErrorBoundary>

      {loading ? (
        <UISkeleton rows={20} />
      ) : (
        <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
          <Work work={data.work} />
        </ErrorBoundary>
      )}
    </Layout>
  );
};

export default ScreensWork;
