import React, { useState } from "react";
import Collection from "../../components/Collection/Collection";
import CollectionSearch from "../../components/Collection/Search";
import { useQuery } from "@apollo/react-hooks";
import {
  GET_COLLECTION,
  GET_COLLECTIONS,
  DELETE_COLLECTION,
} from "../../components/Collection/collection.gql";
import Error from "../../components//UI/Error";
import UILoadingPage from "../../components//UI/LoadingPage";
import UISkeleton from "../../components//UI/Skeleton";
import { Link, useParams, useHistory } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import UIModalDelete from "../../components/UI/Modal/Delete";
import { toastWrapper } from "../../services/helpers";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import Layout from "../Layout";

const ScreensCollection = () => {
  const { id } = useParams();
  const history = useHistory();
  const [modalOpen, setModalOpen] = useState(false);
  const { data, loading, error } = useQuery(GET_COLLECTION, {
    variables: { id },
  });
  const [deleteCollection] = useMutation(DELETE_COLLECTION, {
    onCompleted({ deleteCollection }) {
      toastWrapper(
        "is-success",
        `Collection ${deleteCollection.name} deleted successfully`
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

  function getCrumbs() {
    return [
      {
        label: "Collections",
        route: "/collection/list",
      },
      {
        label: data.collection.name,
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
                    <h1 className="title">{data.collection.name || ""}</h1>
                  </div>
                  <div className="column is-one-third buttons has-text-right">
                    <Link
                      to={`/collection/form/${id}`}
                      className="button is-primary"
                      data-testid="edit-button"
                    >
                      Edit
                    </Link>
                    <button
                      className="button"
                      onClick={onOpenModal}
                      data-testid="delete-button"
                    >
                      Delete
                    </button>
                  </div>
                </div>

                <Collection collection={data.collection} />
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
          thingToDeleteLabel={`Collection ${data.collection.name}`}
        />
      )}
    </Layout>
  );
};

export default ScreensCollection;
