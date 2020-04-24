import React, { useState, useEffect, useRef } from "react";
import CollectionListRow from "../../components/Collection/ListRow";
import { useQuery } from "@apollo/react-hooks";
import {
  GET_COLLECTIONS,
  DELETE_COLLECTION,
} from "../../components/Collection/collection.query";
import Error from "../../components/UI/Error";
import UILoadingPage from "../../components/UI/LoadingPage";
import { Link, useHistory } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import { toastWrapper } from "../../services/helpers";
import Layout from "../Layout";
import UIModalDelete from "../../components/UI/Modal/Delete";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";

const ScreensCollectionList = () => {
  const { data, loading, error } = useQuery(GET_COLLECTIONS);
  const [filteredCollections, setFilteredCollections] = useState([]);
  const [activeCollection, setActiveCollection] = useState();
  const [modalOpen, setModalOpen] = useState(false);
  const inputEl = useRef(null);

  useEffect(() => {
    if (data && data.collections) {
      setFilteredCollections(data.collections);
    }
  }, [data]);

  const [deleteCollection] = useMutation(DELETE_COLLECTION, {
    onCompleted({ deleteCollection }) {
      toastWrapper(
        "is-success",
        `Collection ${deleteCollection.name} deleted successfully`
      );
    },
    refetchQueries(mutationResult) {
      return [{ query: GET_COLLECTIONS }];
    },
  });

  if (loading) {
    return <UILoadingPage />;
  }
  if (error) {
    return <Error error={error} />;
  }

  const onOpenModal = (collectionObj) => {
    setActiveCollection(collectionObj);
    setModalOpen(true);
  };

  const onCloseModal = () => {
    setActiveCollection();
    setModalOpen(false);
  };

  const handleDeleteClick = () => {
    setModalOpen(false);
    deleteCollection({ variables: { collectionId: activeCollection.id } });
    setActiveCollection();
  };

  const createCrumbs = () => {
    return [
      {
        label: "Collections",
        link: "/collection/list",
      },
    ];
  };

  const handleFilterChange = (e) => {
    const searchValue = inputEl.current.value.toLowerCase();

    if (searchValue) {
      setFilteredCollections(
        data.collections.filter((collection) =>
          collection.name.toLowerCase().includes(searchValue)
        )
      );
    } else {
      setFilteredCollections(data.collections);
    }
  };

  return (
    <Layout>
      <section className="section" data-testid="collection-list-wrapper">
        <div className="container">
          <UIBreadcrumbs items={[{ label: "Themes & Collections" }]} />

          <div className="columns">
            <div className="column is-6">
              <div className="box">
                <h1 className="title">Collections</h1>
                <h2 className="subtitle">
                  Each <span className="is-italic">Work</span> must live in a
                  Collection.
                </h2>
                <Link to="/collection/form" className="button is-primary">
                  Add new collection
                </Link>
              </div>
            </div>
            <div className="column is-6">
              <div className="box">
                <h2 className="title is-size-4">Themes</h2>
                <p className="subtitle">
                  Customized groupings of{" "}
                  <span className="is-italic">Works</span>
                </p>
                <Link to="/" className="button">
                  View themes
                </Link>
              </div>
            </div>
          </div>
          <div className="box" data-testid="collection-list">
            <h3 className="title is-size-5">All Collections</h3>
            <div className="field">
              <input
                className="input"
                type="text"
                placeholder="Search collections"
              />
            </div>
            <ul>
              {filteredCollections.length > 0 &&
                filteredCollections.map((collection) => (
                  <CollectionListRow
                    key={collection.id}
                    collection={collection}
                    onOpenModal={onOpenModal}
                  />
                ))}
            </ul>
            {data.collections.length === 0 && (
              <div className="content">
                <p className="notification">No collections returned</p>
              </div>
            )}
          </div>
        </div>
      </section>
      <UIModalDelete
        isOpen={modalOpen}
        handleClose={onCloseModal}
        handleConfirm={handleDeleteClick}
        thingToDeleteLabel={`Collection ${
          activeCollection ? activeCollection.name : " "
        }`}
      />
    </Layout>
  );
};

export default ScreensCollectionList;
