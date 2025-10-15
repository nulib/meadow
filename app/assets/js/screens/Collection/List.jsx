import React, { useState, useEffect, useRef } from "react";
import {
  GET_COLLECTIONS,
  DELETE_COLLECTION,
} from "@js/components/Collection/collection.gql.js";
import Error from "@js/components/UI/Error";
import { Link } from "react-router-dom";
import { useMutation, useQuery } from "@apollo/client/react";
import { toastWrapper } from "@js/services/helpers";
import Layout from "../Layout";
import UIFormInput from "@js/components/UI/Form/Input";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import CollectionsList from "@js/components/Collection/List";
import { ErrorBoundary } from "react-error-boundary";
import { IconAdd } from "@js/components/Icon";
import {
  ActionHeadline,
  Breadcrumbs,
  FallbackErrorComponent,
  Message,
  ModalDelete,
  PageTitle,
  SearchBarRow,
  Skeleton,
} from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";

const ScreensCollectionList = () => {
  const { data, loading, error } = useQuery(GET_COLLECTIONS);
  const [filteredCollections, setFilteredCollections] = useState([]);
  const [activeCollection, setActiveCollection] = useState();
  const [modalOpen, setModalOpen] = useState(false);
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "All Collections" });
  }, []);

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
          <Breadcrumbs items={[{ label: "Collections", isActive: true }]} />

          <div className="block">
            <ActionHeadline>
              <PageTitle>Collections</PageTitle>
              <AuthDisplayAuthorized level="MANAGER">
                <Link to="/collection/form" className="button is-primary">
                  <IconAdd />
                  <span>Add new collection</span>
                </Link>
              </AuthDisplayAuthorized>
            </ActionHeadline>
          </div>

          {/* TODO: Complete this */}
          {/* <Message>
            <dl>
              <dt># of Collections</dt>
              <dd>[fill this in]</dd>
            </dl>
          </Message> */}

          <div className="" data-testid="collection-list">
            {loading ? (
              <Skeleton rows={10} />
            ) : (
              <>
                <SearchBarRow isCentered>
                  <UIFormInput
                    placeholder="Search collections"
                    name="collectionSearch"
                    label="Filter collections"
                    onChange={handleFilterChange}
                    data-testid="input-collections-filter"
                  />
                </SearchBarRow>

                <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
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

      <ModalDelete
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
