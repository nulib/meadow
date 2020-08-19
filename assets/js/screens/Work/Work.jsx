import React, { useState } from "react";
import { useMutation, useQuery } from "@apollo/client";
import {
  CREATE_SHARED_LINK,
  GET_WORK,
  UPDATE_WORK,
  DELETE_WORK,
} from "../../components/Work/work.gql.js";
import UIModalDelete from "../../components/UI/Modal/Delete";
import { useHistory } from "react-router-dom";
import { useParams } from "react-router-dom";
import Layout from "../Layout";
import UISkeleton from "../../components/UI/Skeleton";
import Work from "../../components/Work/Work";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import { toastWrapper } from "../../services/helpers";
import { Link } from "react-router-dom";
import WorkTagsList from "../../components/Work/TagsList";
import WorkHeaderButtons from "../../components/Work/HeaderButtons";
import WorkSharedLinkNotification from "../../components/Work/SharedLinkNotification";

const ScreensWork = () => {
  const { id } = useParams();
  const history = useHistory();
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);

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
      <section className="section" data-testid="work-hero">
        <div className="container">
          <UIBreadcrumbs items={breadCrumbs} data-testid="work-breadcrumbs" />
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
                      onOpenModal={onOpenModal}
                      published={data.work.published}
                    />
                  </div>
                </div>

                <div className="content">
                  {createSharedLinkData && (
                    <WorkSharedLinkNotification
                      linkData={createSharedLinkData.createSharedLink}
                    />
                  )}

                  <dl>
                    <dt>Accession Number</dt>
                    <dd>{data.work.accessionNumber}</dd>
                    <dt>Project</dt>
                    <dd>
                      <Link to={`/project/${data.work.project.id}`}>
                        {data.work.project.title}
                      </Link>
                    </dd>
                    <dt>Ingest Sheet</dt>
                    <dd>
                      <Link
                        to={`/project/${data.work.project.id}/ingest-sheet/${data.work.ingestSheet.id}`}
                      >
                        {data.work.ingestSheet.title}
                      </Link>
                    </dd>
                  </dl>
                </div>
              </>
            )}
          </div>
        </div>
      </section>

      {loading ? <UISkeleton rows={20} /> : <Work work={data.work} />}

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

export default ScreensWork;
