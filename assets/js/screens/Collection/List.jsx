import React, { useState, useEffect, useRef } from "react";
import { useQuery } from "@apollo/client";
import {
  GET_COLLECTIONS,
  DELETE_COLLECTION,
} from "@js/components/Collection/collection.gql.js";
import { Button } from "@nulib/admin-react-components";
import Error from "@js/components/UI/Error";
import { Link } from "react-router-dom";
import { useMutation } from "@apollo/client";
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
  const LIMIT = 5;
  const { data, loading, error, fetchMore } = useQuery(GET_COLLECTIONS, {
    variables: { limit: LIMIT, offset: 0 },
  });
  const [filteredCollections, setFilteredCollections] = useState([]);
  const [activeCollection, setActiveCollection] = useState();
  const [hasMoreCollections, setMoreCollections] = useState(true);
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
      return [{ query: GET_COLLECTIONS, variables: { limit: 5, offset: 0 }  }];
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

  const seeMore = () => {
    fetchMore({
      variables: {
        offset: data.collections.length,
      },
      updateQuery: (previousResult, { fetchMoreResult }) => {
        if (!fetchMoreResult) return previousResult;

        if (fetchMoreResult.collections.length < LIMIT) {
          setMoreCollections(true);
        }

        return {
          collections: [
            ...previousResult.collections,
            ...fetchMoreResult.collections,
          ],
        };
      },
    });
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
                <br />
                <Button
                  className="button is-primary"
                  disabled={!hasMoreCollections}
                  onClick={seeMore}
                >
                  See More
                </Button>
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
