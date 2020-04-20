import React, { useState } from "react";
import { useMutation, useQuery } from "@apollo/react-hooks";
import {
  GET_WORK,
  UPDATE_WORK,
  DELETE_WORK
} from "../../components/Work/work.query";
import UIModalDelete from "../../components/UI/Modal/Delete";
import { useHistory } from "react-router-dom";
import { useParams } from "react-router-dom";
import Layout from "../Layout";
import Error from "../../components/UI/Error";
import UILoadingPage from "../../components/UI/LoadingPage";
import Work from "../../components/Work/Work";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import ButtonGroup from "../../components/UI/ButtonGroup";
import { toastWrapper } from "../../services/helpers";

const ScreensWork = () => {
  const { id } = useParams();
  const { data, loading, error } = useQuery(GET_WORK, {
    variables: { id }
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
    }
  });
  const [updateWork] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      toastWrapper(
        "is-success",
        `Work has been ${updateWork.published ? "published" : "unpublished"}`
      );
    }
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

  if (loading) return <UILoadingPage />;
  if (error) return <Error error={error} />;

  const {
    work: { accessionNumber, published, descriptiveMetadata, project, sheet }
  } = data;

  const breadCrumbs = [
    {
      label: `${project.name}`,
      route: `/project/${project.id}`
    },
    {
      label: `${sheet.name}`,
      route: `/project/${project.id}/ingest-sheet/${sheet.id}`
    },
    {
      label: accessionNumber,
      isActive: true
    }
  ];

  const handlePublishClick = () => {
    let workUpdateInput = {
      published: !published
    };

    updateWork({
      variables: { id, work: workUpdateInput }
    });
  };

  return (
    <Layout>
      <section className="section" data-testid="work-hero">
        <div className="container">
          <UIBreadcrumbs items={breadCrumbs} data-testid="work-breadcrumbs" />
          <div className="box">
            <h1 className="title">
              {accessionNumber}{" "}
              <span className={`tag ${published ? "is-info" : "is-warning"}`}>
                {published ? "Published" : "Not Published"}
              </span>
            </h1>
            <h2 className="subtitle">Work Accession Number</h2>
            <ButtonGroup>
              <button
                className="button is-primary is-outlined"
                data-testid="publish-button"
                onClick={handlePublishClick}
              >
                {!published ? "Publish" : "Unpublish"}
              </button>
              <button
                className="button"
                data-testid="delete-button"
                onClick={onOpenModal}
              >
                Delete
              </button>
            </ButtonGroup>
          </div>
          <Work work={data.work} />
        </div>
      </section>

      <UIModalDelete
        isOpen={deleteModalOpen}
        handleClose={onCloseModal}
        handleConfirm={handleDeleteClick}
        thingToDeleteLabel={`Work ${
          descriptiveMetadata
            ? descriptiveMetadata.title || accessionNumber
            : accessionNumber
        }`}
      />
    </Layout>
  );
};

export default ScreensWork;
