import React, { useState } from "react";
import Collection from "../../components/Collection/Collection";
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
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { Button } from "@nulib/admin-react-components";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import CollectionTags from "@js/components/Collection/Tags";

const ScreensCollection = () => {
  const { id } = useParams();
  const history = useHistory();
  const [modalOpen, setModalOpen] = useState(false);
  const { data, loading, error } = useQuery(GET_COLLECTION, {
    variables: { id },
  });

  const handleViewAllWorksClick = () => {
    history.push("/search", {
      externalFacet: {
        facetComponentId: "Collection",
        value: data.collection.title,
      },
    });
  };

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
                <header className="is-flex is-justify-content-space-between mb-3">
                  <div>
                    <h1 className="title">{data.collection.title || ""}</h1>
                  </div>
                  <div className="buttons">
                    <AuthDisplayAuthorized action="edit">
                      <Link
                        to={`/collection/form/${id}`}
                        className="button is-primary"
                        data-testid="edit-button"
                      >
                        Edit
                      </Link>
                    </AuthDisplayAuthorized>
                    <Button
                      onClick={handleViewAllWorksClick}
                      data-testid="view-works-button"
                    >
                      <span className="icon">
                        <FontAwesomeIcon icon="images" />
                      </span>
                      <span>View works</span>
                    </Button>
                  </div>
                </header>

                <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
                  <CollectionTags collection={data.collection} />
                  <Collection collection={data.collection} />
                </ErrorBoundary>
              </>
            )}
          </div>

          <div className="my-4">
            <AuthDisplayAuthorized action="delete">
              <Button
                isDanger
                onClick={onOpenModal}
                data-testid="delete-button"
              >
                Delete
              </Button>
            </AuthDisplayAuthorized>
          </div>
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
