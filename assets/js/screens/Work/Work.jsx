import React, { useState } from "react";
import { useMutation, useQuery } from "@apollo/client";
import {
  CREATE_SHARED_LINK,
  GET_WORK,
  UPDATE_WORK,
} from "@js/components/Work/work.gql.js";
import { useHistory, useParams } from "react-router-dom";
import Layout from "../Layout";
import UISkeleton from "@js/components/UI/Skeleton";
import Work from "@js/components/Work/Work";
import { toastWrapper } from "@js/services/helpers";
import WorkTagsList from "@js/components/Work/TagsList";
import WorkHeaderButtons from "@js/components/Work/HeaderButtons";
import WorkSharedLinkNotification from "@js/components/Work/SharedLinkNotification";
import WorkPublicLinkNotification from "@js/components/Work/PublicLinkNotification";
import WorkMultiEditBar from "@js/components/Work/MultiEditBar";
import { useBatchState } from "@js/context/batch-edit-context";
import { ErrorBoundary } from "react-error-boundary";
import useFacetLinkClick from "@js/hooks/useFacetLinkClick";
import {
  Breadcrumbs,
  FallbackErrorComponent,
  LevelItem,
  PageTitle,
  Skeleton,
} from "@js/components/UI/UI";
import classNames from "classnames";
import { isMobile } from "react-device-detect";
import useGTM from "@js/hooks/useGTM";
import { Helmet } from "react-helmet";
import { WorkProvider } from "@js/context/work-context";

const ScreensWork = () => {
  const params = useParams();
  const { id } = params;
  const history = useHistory();
  const batchState = useBatchState();
  const [isWorkOpen, setIsWorkOpen] = useState(false);
  const { handleFacetLinkClick } = useFacetLinkClick();
  const { loadDataLayer } = useGTM();

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
    onCompleted({ work }) {
      const creators =
        work.descriptiveMetadata.creator.length > 0
          ? work.descriptiveMetadata.creator.map((c) => c.term?.label)
          : [];
      const contributors =
        work.descriptiveMetadata.contributor.length > 0
          ? work.descriptiveMetadata.contributor.map((c) => c.term?.label)
          : [];
      const subjects =
        work.descriptiveMetadata.subject.length > 0
          ? work.descriptiveMetadata.subject.map((s) => s.term?.label)
          : [];
      loadDataLayer({
        adminset: work.administrativeMetadata.libraryUnit?.label,
        collections: [work.collection?.title],
        creatorsContributors: [...creators, ...contributors],
        isPublished: work.published,
        pageTitle: `${getTitle()} - Work Details`,
        rightsStatement: work.descriptiveMetadata.rightsStatement?.label,
        subjects,
        visibility: work.visibility?.label,
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

  const [createSharedLink, { data: createSharedLinkData }] =
    useMutation(CREATE_SHARED_LINK);

  if (error) {
    return null;
  }

  function getTitle() {
    if (!data) return "";
    return data.work.descriptiveMetadata.title || "";
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
      <Helmet>
        <title>{getTitle()} - Meadow - Northwestern University</title>
      </Helmet>
      {isMulti() && (
        <WorkMultiEditBar
          currentIndex={multiCurrentIndex}
          handleMultiNavClick={handleMultiNavClick}
          totalItems={multiTotalItems}
        />
      )}
      <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
        <section className="section" data-testid="work-hero">
          <div className="container">
            <Breadcrumbs items={breadCrumbs} data-testid="work-breadcrumbs" />

            <div className="box">
              {loading ? (
                <Skeleton rows={5} />
              ) : (
                <>
                  <PageTitle data-testid="work-page-title">
                    {data.work.descriptiveMetadata.title || "Untitled"}{" "}
                  </PageTitle>

                  <div className="is-flex-desktop is-justify-content-space-between is-align-items-flex-start block">
                    {data.work.collection && data.work.collection.title && (
                      <div
                        className={classNames({
                          block: isMobile,
                        })}
                      >
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
                      </div>
                    )}
                    <WorkHeaderButtons
                      handleCreateSharableBtnClick={
                        handleCreateSharableBtnClick
                      }
                      handlePublishClick={handlePublishClick}
                      published={data.work.published}
                      hasCollection={data.work.collection ? true : false}
                    />
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

                    <hr />
                    <div className="level" data-testid="work-headers">
                      <LevelItem
                        data-testid="work-header-id"
                        heading="Work id"
                        content={data.work.id}
                        contentClassname="is-size-6"
                      />
                      <LevelItem
                        data-testid="work-header-ark"
                        heading="Ark"
                        content={data.work.descriptiveMetadata.ark || ""}
                        contentClassname="is-size-6"
                      />
                      <LevelItem
                        data-testid="work-header-accession-number"
                        heading="Accession number"
                        content={data.work.accessionNumber || ""}
                        contentClassname="is-size-6"
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
        <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
          <WorkProvider>
            <Work work={data.work} />
          </WorkProvider>
        </ErrorBoundary>
      )}
    </Layout>
  );
};

export default ScreensWork;
