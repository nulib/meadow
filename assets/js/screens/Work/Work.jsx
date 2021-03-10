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
import WorkTagsList from "../../components/Work/TagsList";
import WorkHeaderButtons from "../../components/Work/HeaderButtons";
import WorkSharedLinkNotification from "../../components/Work/SharedLinkNotification";
import WorkPublicLinkNotification from "../../components/Work/PublicLinkNotification";
import WorkMultiEditBar from "../../components/Work/MultiEditBar";
import { useBatchState } from "../../context/batch-edit-context";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import useFacetLinkClick from "@js/hooks/useFacetLinkClick";
import UILevelItem from "@js/components/UI/LevelItem";

const ScreensWork = () => {
  const params = useParams();
  const { id } = params;
  const history = useHistory();
  const batchState = useBatchState();
  const [isWorkOpen, setIsWorkOpen] = useState(false);
  const { handleFacetLinkClick } = useFacetLinkClick();

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

  return (
    <Layout>
      {isMulti() && (
        <WorkMultiEditBar
          currentIndex={multiCurrentIndex}
          handleMultiNavClick={handleMultiNavClick}
          totalItems={multiTotalItems}
        />
      )}
      <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
        <section className="section" data-testid="work-hero">
          <div className="container">
            <UIBreadcrumbs items={breadCrumbs} data-testid="work-breadcrumbs" />

            <div className="box">
              {loading ? (
                <UISkeleton rows={5} />
              ) : (
                <>
                  <div className="is-flex is-justify-content-space-between mb-5">
                    <div>
                      <h1 className="title">
                        {data.work.descriptiveMetadata.title || "Untitled"}{" "}
                      </h1>
                      {data.work.collection && data.work.collection.title && (
                        <p className="subtitle">
                          <span className="heading">Collection</span>
                          <a
                            onClick={() =>
                              handleFacetLinkClick(
                                "Collection",
                                data.work.collection.title
                              )
                            }
                          >
                            {data.work.collection.title}
                          </a>
                        </p>
                      )}
                    </div>
                    <div>
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
                  <WorkTagsList work={data.work} />

                  <div className="content">
                    {createSharedLinkData && (
                      <WorkSharedLinkNotification
                        linkData={createSharedLinkData.createSharedLink}
                      />
                    )}
                    {isWorkOpen && (
                      <WorkPublicLinkNotification workId={data.work.id} />
                    )}
                    <div className="level">
                      <UILevelItem
                        heading="Work id"
                        content={data.work.id}
                        contentClassname="is-size-5"
                      />
                      <UILevelItem
                        heading="Ark"
                        content={data.work.descriptiveMetadata.ark || ""}
                        contentClassname="is-size-5"
                      />
                      <UILevelItem
                        heading="Accession number"
                        content={data.work.accessionNumber || ""}
                        contentClassname="is-size-5"
                      />
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
