import React, { useState } from "react";
import { useMutation, useQuery } from "@apollo/client";
import {
  CREATE_SHARED_LINK,
  GET_WORK,
  UPDATE_WORK,
  DELETE_WORK,
} from "../../components/Work/work.gql.js";
import UIModalDelete from "../../components/UI/Modal/Delete";
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
import WorkMultiEditBar from "../../components/Work/MultiEditBar";
import { useBatchState } from "../../context/batch-edit-context";
import { ErrorBoundary } from "react-error-boundary";
import { Button } from "@nulib/admin-react-components";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { DisplayAuthorized } from "@js/components/Auth/DisplayAuthorized";

const ScreensWork = () => {
  const params = useParams();
  const { id } = params;
  const history = useHistory();
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const batchState = useBatchState();

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

  const [deleteWork, { data: deleteWorkData }] = useMutation(DELETE_WORK, {
    onCompleted({ deleteWork: { project, sheet, descriptiveMetadata } }) {
      toastWrapper(
        "is-success",
        `Work ${
          descriptiveMetadata ? descriptiveMetadata.title : ""
        } deleted successfully`
      );
      history.push(`/project/${project.id}/ingest-sheet/${sheet.id}`);
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
    createSharedLink({
      variables: {
        workId: id,
      },
    });
  };

  const handleDeleteClick = () => {
    deleteWork({ variables: { workId: id } });
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

  const onOpenModal = () => {
    setDeleteModalOpen(true);
  };

  const onCloseModal = () => {
    setDeleteModalOpen(false);
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
      <ErrorBoundary FallbackComponent={ErrorFallbackHeader}>
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
                              <Link to={`/project/${data.work.project.id}`}>
                                {data.work.project.title}
                              </Link>
                            </p>
                          )}
                      </div>
                      <div className="column">
                        <p>
                          <strong>Ingest Sheet</strong>
                        </p>
                        <p>
                          {data.work.project && data.work.ingestSheet && (
                            <Link
                              to={`/project/${data.work.project.id}/ingest-sheet/${data.work.ingestSheet.id}`}
                            >
                              {data.work.ingestSheet.title}
                            </Link>
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
        <ErrorBoundary FallbackComponent={ErrorFallback}>
          <Work work={data.work} />
          <div className="container buttons">
            <DisplayAuthorized action="delete">
              <Button data-testid="delete-button" onClick={onOpenModal}>
                <span className="icon">
                  <FontAwesomeIcon icon="trash" />
                </span>
                <span>Delete this work</span>
              </Button>
            </DisplayAuthorized>
          </div>
        </ErrorBoundary>
      )}

      {data && (
        <UIModalDelete
          isOpen={deleteModalOpen}
          handleClose={onCloseModal}
          handleConfirm={handleDeleteClick}
          thingToDeleteLabel={`Work ${
            data.work.descriptiveMetadata
              ? data.work.descriptiveMetadata.title || data.work.accessionNumber
              : data.work.accessionNumber
          }`}
        />
      )}
    </Layout>
  );
};

function ErrorFallback({ error }) {
  return (
    <div role="alert" className="notification is-danger">
      <p>There was an error displaying the Work</p>
      <p>
        <strong>Error</strong>: {error.message}
      </p>
    </div>
  );
}

function ErrorFallbackHeader({ error }) {
  return (
    <div role="alert" className="notification is-danger">
      <p>There was an error displaying the header of the Work</p>
      <p>
        <strong>Error</strong>: {error.message}
      </p>
    </div>
  );
}

export default ScreensWork;
