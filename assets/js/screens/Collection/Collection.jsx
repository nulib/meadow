import React, { useState } from "react";
import Collection from "@js/components/Collection/Collection";
import { useQuery } from "@apollo/client";
import {
  GET_COLLECTION,
  GET_COLLECTIONS,
  DELETE_COLLECTION,
  UPDATE_COLLECTION,
} from "@js/components/Collection/collection.gql";
import { Link, useParams, useHistory } from "react-router-dom";
import { useMutation } from "@apollo/client";
import { toastWrapper } from "@js/services/helpers";
import Layout from "@js/screens/Layout";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { ErrorBoundary } from "react-error-boundary";
import { Button } from "@nulib/admin-react-components";
import CollectionTags from "@js/components/Collection/Tags";
import IconEdit from "@js/components/Icon/Edit";
import {
  ActionHeadline,
  Breadcrumbs,
  Error,
  FallbackErrorComponent,
  ModalDelete,
  PageTitle,
  Skeleton,
} from "@js/components/UI/UI";

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
            <Skeleton rows={1} />
          ) : (
            <Breadcrumbs items={getCrumbs()} />
          )}

          <div className="box">
            {loading ? (
              <Skeleton rows={10} />
            ) : (
              <>
                <ActionHeadline>
                  <PageTitle>{data.collection.title || ""}</PageTitle>
                  <div className="buttons">
                    <AuthDisplayAuthorized>
                      <Link
                        to={`/collection/form/${id}`}
                        className="button is-primary"
                        data-testid="edit-button"
                      >
                        <IconEdit className="icon" />
                        <span>Edit</span>
                      </Link>
                    </AuthDisplayAuthorized>
                  </div>
                </ActionHeadline>

                <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
                  <CollectionTags collection={data.collection} />
                  <Collection collection={data.collection} />
                </ErrorBoundary>
              </>
            )}
          </div>

          <div className="my-4">
            <AuthDisplayAuthorized level="MANAGER">
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
        <ModalDelete
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
