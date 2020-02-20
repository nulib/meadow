import React, { useState } from "react";
import Collection from "../../components/Collection/Collection";
import { useQuery } from "@apollo/react-hooks";
import {
  GET_COLLECTION,
  GET_COLLECTIONS,
  DELETE_COLLECTION
} from "../../components/Collection/collection.query";
import Error from "../../components//UI/Error";
import Loading from "../../components//UI/Loading";
import { Link, useParams, useHistory } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import UIModalDelete from "../../components/UI/Modal/Delete";
import { useToasts } from "react-toast-notifications";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import Layout from "../Layout";

const ScreensCollection = () => {
  const { id } = useParams();
  const { addToast } = useToasts();
  const history = useHistory();
  const [modalOpen, setModalOpen] = useState(false);
  const { data, loading, error } = useQuery(GET_COLLECTION, {
    variables: { id }
  });
  const [deleteCollection] = useMutation(DELETE_COLLECTION, {
    onCompleted({ deleteCollection }) {
      addToast(`Collection ${deleteCollection.name} deleted successfully`, {
        appearance: "success",
        autoDismiss: true
      });
      history.push("/collection/list");
    },
    refetchQueries(mutationResult) {
      return [{ query: GET_COLLECTIONS }];
    }
  });

  if (loading) return <Loading />;
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

  const crumbs = [
    {
      label: "Collections",
      route: "/collection/list"
    },
    {
      label: data.collection.name,
      route: `/collection/${id}`,
      isActive: true
    }
  ];

  return (
    <Layout>
      <section className="hero is-light">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">{data.collection.name || ""}</h1>
            <h2 className="subtitle">Collection</h2>
            <div className="buttons">
              <Link to={`/collection/form/${id}`} className="button is-primary">
                Edit
              </Link>
              <button className="button" onClick={onOpenModal}>
                Delete
              </button>
            </div>
          </div>
        </div>
      </section>
      <UIBreadcrumbs items={crumbs} />
      <section className="section">
        <Collection {...data.collection} />
      </section>

      <UIModalDelete
        isOpen={modalOpen}
        handleClose={onCloseModal}
        handleConfirm={handleDeleteClick}
        thingToDeleteLabel={`Collection ${data.collection.name}`}
      />
    </Layout>
  );
};

export default ScreensCollection;
