import React, { useState, useEffect, useRef } from "react";
import CollectionListRow from "../../components/Collection/ListRow";
import { useQuery } from "@apollo/client";
import {
  GET_COLLECTIONS,
  DELETE_COLLECTION,
} from "../../components/Collection/collection.gql.js";
import Error from "../../components/UI/Error";
import UISkeleton from "../../components/UI/Skeleton";
import { Link, useHistory } from "react-router-dom";
import { useMutation } from "@apollo/client";
import { toastWrapper } from "../../services/helpers";
import Layout from "../Layout";
import UIModalDelete from "../../components/UI/Modal/Delete";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import UIFormInput from "../../components/UI/Form/Input";
import UIFormField from "../../components/UI/Form/Field";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

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
          <UIBreadcrumbs
            items={[{ label: "Themes & Collections", isActive: true }]}
          />

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
            {loading ? (
              <UISkeleton rows={10} />
            ) : (
              <>
                <h3 className="title is-size-5">All Collections</h3>
                <UIFormField childClass="has-icons-left">
                  <UIFormInput
                    placeholder="Search collections"
                    name="collectionSearch"
                    label="Filter collections"
                  />
                  <span className="icon is-small is-left">
                    <FontAwesomeIcon icon="search" />
                  </span>
                </UIFormField>

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
              </>
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
