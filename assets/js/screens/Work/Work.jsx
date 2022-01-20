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
  ActionHeadline,
  Breadcrumbs,
  FallbackErrorComponent,
  Message,
  PageTitle,
  Skeleton,
} from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";
import { Helmet } from "react-helmet";
import { WorkProvider } from "@js/context/work-context";

function getTitle(data) {
  if (!data) return "";
  return data.work?.descriptiveMetadata?.title || "";
}

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
    onError(error) {
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
        pageTitle: `${getTitle(work)} - Work Details`,
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
        <title>{getTitle(data)} - Meadow - Northwestern University</title>
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

            {loading ? (
              <Skeleton rows={5} />
            ) : (
              <>
                <ActionHeadline>
                  <PageTitle data-testid="work-page-title">
                    {data.work.descriptiveMetadata.title || ""}{" "}
                  </PageTitle>
                  <WorkHeaderButtons
                    handleCreateSharableBtnClick={handleCreateSharableBtnClick}
                    handlePublishClick={handlePublishClick}
                    published={data.work.published}
                    hasCollection={data.work.collection ? true : false}
                  />
                </ActionHeadline>

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
                </div>

                <Message data-testid="work-headers">
                  <dl>
                    <dt data-testid="work-header-id">Id</dt>
                    <dd>{data.work.id}</dd>
                    <dt data-testid="work-header-ark">Ark</dt>
                    <dd>{data.work.descriptiveMetadata.ark || ""}</dd>
                    <dt data-testid="work-header-accession-number">
                      Accession number
                    </dt>
                    <dd>{data.work.accessionNumber || ""}</dd>
                    {data.work.collection?.title && (
                      <>
                        <dt>Collection</dt>
                        <dd>
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
                        </dd>
                      </>
                    )}
                  </dl>
                </Message>
              </>
            )}
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
