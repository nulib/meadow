import React, { useState } from "react";
import Collection from "@js/components/Collection/Collection";
import {
  GET_COLLECTION,
  GET_COLLECTIONS,
  DELETE_COLLECTION,
  UPDATE_COLLECTION,
} from "@js/components/Collection/collection.gql";
import { Link, useParams, useHistory } from "react-router-dom";
import { useMutation, useQuery } from "@apollo/client/react";
import { toastWrapper } from "@js/services/helpers";
import Layout from "@js/screens/Layout";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { ErrorBoundary } from "react-error-boundary";
import { Button } from "@nulib/design-system";
import CollectionTags from "@js/components/Collection/Tags";
import { IconEdit } from "@js/components/Icon";
import {
  ActionHeadline,
  Breadcrumbs,
  Error,
  FallbackErrorComponent,
  ModalDelete,
  PageTitle,
  Skeleton,
} from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";
import { Helmet } from "react-helmet";

const ScreensCollection = () => {
  const { id } = useParams();
  const history = useHistory();
  const [modalOpen, setModalOpen] = useState(false);
  const { data, loading, error } = useQuery(GET_COLLECTION, {
    variables: { id },
  });
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    {
      data && // Update GTM datalayer
        loadDataLayer({
          pageTitle: `${data.collection.title} - Collection`,
          visibility: data.collection?.visibility?.label,
        });
    }
  }, [data]);

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
  //if (!data) return null;

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

  function getTitle() {
    if (!data) return "";
    return data.collection.title || "";
  }

  return (
    <Layout>
      <Helmet>
        <title>{getTitle()} - Meadow - Northwestern University</title>
      </Helmet>
      <section className="section" data-testid="collection-screen-hero">
        <div className="container">
          {loading ? (
            <Skeleton rows={1} />
          ) : (
            <Breadcrumbs items={getCrumbs()} />
          )}

          <div className="">
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
                        <span className="icon">
                          <IconEdit />
                        </span>
                        <span>Edit</span>
                      </Link>
                    </AuthDisplayAuthorized>
                  </div>
                </ActionHeadline>

                <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
                  <CollectionTags collection={data.collection} />
                  <div className="box">
                    <Collection collection={data.collection} />
                  </div>
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
