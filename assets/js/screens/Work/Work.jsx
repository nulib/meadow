import React, { useState } from "react";
import { useMutation, useQuery } from "@apollo/react-hooks";
import {
  GET_WORK,
  UPDATE_WORK,
  DELETE_WORK,
} from "../../components/Work/work.gql.js";
import UIModalDelete from "../../components/UI/Modal/Delete";
import { useHistory } from "react-router-dom";
import { useParams } from "react-router-dom";
import Layout from "../Layout";
import Error from "../../components/UI/Error";
import UISkeleton from "../../components/UI/Skeleton";
import Work from "../../components/Work/Work";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import { setVisibilityClass, toastWrapper } from "../../services/helpers";
import { Link } from "react-router-dom";

const ScreensWork = () => {
  const { id } = useParams();
  const { data, loading, error } = useQuery(GET_WORK, {
    variables: { id },
  });
  const history = useHistory();
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
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

  const handleDeleteClick = () => {
    deleteWork({ variables: { workId: id } });
  };

  const onOpenModal = () => {
    setDeleteModalOpen(true);
  };

  const onCloseModal = () => {
    setDeleteModalOpen(false);
  };

  if (error) return <Error error={error} />;

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
                  <div className="column is-two-thirds">
                    <h1 className="title">
                      {data.work.descriptiveMetadata.title || "Untitled"}{" "}
                    </h1>
                    <p>
                      <span
                        className={`tag ${
                          data.work.published ? "is-info" : "is-warning"
                        }`}
                      >
                        {data.work.published ? "Published" : "Not Published"}
                      </span>{" "}
                      <span
                        className={`tag ${setVisibilityClass(
                          data.work.visibility.id
                        )}`}
                      >
                        {data.work.visibility.label}
                      </span>{" "}
                      <span className={`tag is-info`}>
                        {data.work.workType.label}
                      </span>
                    </p>
                  </div>
                  <div className="column is-one-third">
                    <div className="buttons is-right">
                      <button
                        className={`button is-primary ${
                          data.work.published ? "is-outlined" : ""
                        }`}
                        data-testid="publish-button"
                        onClick={handlePublishClick}
                      >
                        {!data.work.published ? "Publish" : "Unpublish"}
                      </button>
                      <button
                        className="button"
                        data-testid="delete-button"
                        onClick={onOpenModal}
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>

                <div className="content">
                  <dl>
                    <dt>Accession Number</dt>
                    <dd>{data.work.accessionNumber}</dd>
                    <dt>Project</dt>
                    <dd>
                      <Link to={`/project/${data.work.project.id}`}>
                        {data.work.project.name}
                      </Link>
                    </dd>
                    <dt>Ingest Sheet</dt>
                    <dd>
                      <Link
                        to={`/project/${data.work.project.id}/ingest-sheet/${data.work.sheet.id}`}
                      >
                        {data.work.sheet.name}
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
