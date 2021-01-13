import React, { useState } from "react";
import Collection from "../../components/Collection/Collection";
import CollectionSearch from "../../components/Collection/Search";
import { useQuery } from "@apollo/client";
import {
  GET_COLLECTION,
  GET_COLLECTIONS,
  DELETE_COLLECTION,
  UPDATE_COLLECTION,
} from "../../components/Collection/collection.gql";
import Error from "../../components//UI/Error";
import UISkeleton from "../../components//UI/Skeleton";
import { Link, useParams, useHistory } from "react-router-dom";
import { useMutation } from "@apollo/client";
import UIModalDelete from "../../components/UI/Modal/Delete";
import { toastWrapper } from "../../services/helpers";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import Layout from "../Layout";
import { DisplayAuthorized } from "@js/components/Auth/DisplayAuthorized";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";

const ScreensCollection = () => {
  const { id } = useParams();
  const history = useHistory();
  const [modalOpen, setModalOpen] = useState(false);
  const { data, loading, error } = useQuery(GET_COLLECTION, {
    variables: { id },
  });

  const [updateCollection] = useMutation(UPDATE_COLLECTION, {
    onCompleted({ updateCollection }) {
      toastWrapper(
        "is-success",
        `Collection has been ${
          updateCollection.published ? "published" : "unpublished"
        }`
      );
    },
    onError(error) {
      toastWrapper("is-danger", "Error publishing Collection");
      console.log("Error publishing collection: ", error);
    },
  });

  const [deleteCollection] = useMutation(DELETE_COLLECTION, {
    onCompleted({ deleteCollection }) {
      toastWrapper(
        "is-success",
        `Collection ${deleteCollection.title} deleted successfully`
      );
      history.push("/collection/list");
    },
    refetchQueries(mutationResult) {
      return [{ query: GET_COLLECTIONS }];
    },
  });

  if (error) return <Error error={error} />;

  const onOpenModal = () => {
    setModalOpen(true);
  };

  const onCloseModal = () => {
    setModalOpen(false);
  };

  const handleDeleteClick = () => {
    setModalOpen(false);
    deleteCollection({ variables: { collectionId: id } });
  };

  const handlePublishClick = () => {
    updateCollection({
      variables: { collectionId: id, published: !data.collection.published },
    });
  };

  function getCrumbs() {
    return [
      {
        label: "Collections",
        route: "/collection/list",
      },
      {
        label: data.collection.title,
        route: `/collection/${id}`,
        isActive: true,
      },
    ];
  }

  return (
    <Layout>
      <section className="section" data-testid="collection-screen-hero">
        <div className="container">
          {loading ? (
            <UISkeleton rows={1} />
          ) : (
            <UIBreadcrumbs items={getCrumbs()} />
          )}

          <div className="box">
            {loading ? (
              <UISkeleton rows={10} />
            ) : (
              <>
                <div className="columns">
                  <div className="column is-two-thirds">
                    <h1 className="title">{data.collection.title || ""}</h1>
                    <span
                      data-testid="published-tag"
                      className={`tag mr-1 ${
                        data.collection.published ? "is-info" : "is-warning"
                      }`}
                    >
                      {data.collection.published
                        ? "Published"
                        : "Not Published"}
                    </span>
                    {data.collection.featured && (
                      <span className={`tag is-info`}>Featured</span>
                    )}
                  </div>
                  <div className="column is-one-third buttons has-text-right">
                    <DisplayAuthorized action="edit">
                      <button
                        className="button is-primary"
                        onClick={handlePublishClick}
                        data-testid="publish-button"
                      >
                        {!data.collection.published ? "Publish" : "Unpublish"}
                      </button>
                      <Link
                        to={`/collection/form/${id}`}
                        className="button is-primary"
                        data-testid="edit-button"
                      >
                        Edit
                      </Link>
                    </DisplayAuthorized>
                    <DisplayAuthorized action="delete">
                      <button
                        className="button"
                        onClick={onOpenModal}
                        data-testid="delete-button"
                      >
                        Delete
                      </button>
                    </DisplayAuthorized>
                  </div>
                </div>
                <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
                  <Collection collection={data.collection} />
                </ErrorBoundary>
              </>
            )}
          </div>

          {loading ? (
            <UISkeleton rows={10} />
          ) : (
            <CollectionSearch collection={data.collection} />
          )}
        </div>
      </section>

      {data && (
        <UIModalDelete
          isOpen={modalOpen}
          handleClose={onCloseModal}
          handleConfirm={handleDeleteClick}
          thingToDeleteLabel={`Collection ${data.collection.title}`}
        />
      )}
    </Layout>
  );
};

export default ScreensCollection;
