import React, { useState, useEffect, useRef } from "react";
import { useQuery } from "@apollo/client";
import {
  GET_COLLECTIONS,
  DELETE_COLLECTION,
} from "@js/components/Collection/collection.gql.js";
import Error from "@js/components/UI/Error";
import UISkeleton from "@js/components/UI/Skeleton";
import { Link } from "react-router-dom";
import { useMutation } from "@apollo/client";
import { toastWrapper } from "@js/services/helpers";
import Layout from "../Layout";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import UIBreadcrumbs from "@js/components/UI/Breadcrumbs";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormField from "@js/components/UI/Form/Field";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { DisplayAuthorized } from "@js/components/Auth/DisplayAuthorized";
import CollectionsList from "@js/components/Collection/List";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import UISearchBarRow from "@js/components/UI/SearchBarRow";

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
        `Collection ${deleteCollection.title} deleted successfully`
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
    const searchValue = e.target.value.toLowerCase();

    if (searchValue) {
      setFilteredCollections(
        data.collections.filter((collection) =>
          collection.title.toLowerCase().includes(searchValue)
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
                <DisplayAuthorized action="edit">
                  <Link to="/collection/form" className="button is-primary">
                    Add new collection
                  </Link>
                </DisplayAuthorized>
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
                <UISearchBarRow>
                  <UIFormInput
                    placeholder="Search collections"
                    name="collectionSearch"
                    label="Filter collections"
                    onChange={handleFilterChange}
                    data-testid="input-collections-filter"
                  />
                </UISearchBarRow>
                <UIFormField childClass="has-icons-left">
                  <span className="icon is-small is-left">
                    <FontAwesomeIcon icon="search" />
                  </span>
                </UIFormField>

                <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
                  <CollectionsList
                    collections={data.collections}
                    filteredCollections={filteredCollections}
                    onOpenModal={onOpenModal}
                  />
                </ErrorBoundary>
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
          activeCollection ? activeCollection.title : " "
        }`}
      />
    </Layout>
  );
};

export default ScreensCollectionList;
