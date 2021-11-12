import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormSelect from "@js/components/UI/Form/Select";
import { toastWrapper, sortItemsArray } from "@js/services/helpers";
import { Button, Notification } from "@nulib/design-system";
import { useMutation, useQuery, useLazyQuery } from "@apollo/client";
import {
  GET_COLLECTION,
  GET_COLLECTIONS,
  SET_COLLECTION_IMAGE,
} from "@js/components/Collection/collection.gql.js";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { IconAlert } from "@js/components/Icon";

function WorkTabsAdministrativeCollection({
  collection,
  handleViewAllWorksClick,
  isEditing,
  workId,
}) {
  const [isHelperMessageVisible, setIsHelperMessageVisible] =
    React.useState(false);
  const [isCollectionImage, setIsCollectionImage] = React.useState(false);
  const { data: collectionsData, loading, error } = useQuery(GET_COLLECTIONS);

  /**
   * Update Collection representative image
   */
  const [setCollectionImage] = useMutation(SET_COLLECTION_IMAGE, {
    onCompleted({ setCollectionImage }) {
      toastWrapper("is-success", "Collection image has been updated");
      setIsCollectionImage(true);
    },
    onError({ graphQLErrors, networkError }) {
      let errorStrings = [];
      if (graphQLErrors.length > 0) {
        errorStrings = graphQLErrors.map(
          ({ message, details }) =>
            `${message}: ${details && details.title ? details.title : ""}`
        );
      }
      toastWrapper(
        "is-danger",
        `Error updating collection image ${errorStrings.join(" \n ")}`
      );
    },
  });

  /**
   * Need this helper query to pull "representativeWork" off the Collection type
   * to determine whether current Work is the representative Collection work.
   */
  const [
    loadCollection,
    { called, loading: loadingLoadCollection, data: dataLoadCollection },
  ] = useLazyQuery(GET_COLLECTION, {
    fetchPolicy: "network-only",
    variables: { id: collection ? collection.id : "" },
    onCompleted({ collection: { representativeWork } }) {
      setIsCollectionImage(
        representativeWork && representativeWork.id === workId ? true : false
      );
    },
    onError({ graphQLErrors, networkError }) {
      console.error("graphQLErrors", graphQLErrors);
      console.error("networkError", networkError);
      toastWrapper(
        "is-danger",
        `Error getting the Work Collection through GraphQL LazyQuery`
      );
    },
  });

  /**
   * Call the lazy query if a Collection exists for the work, and then we
   * pull the representativeWork from the returned Collection to test for a match
   */
  React.useEffect(() => {
    if (!collection) {
      return;
    }
    if (called && loadingLoadCollection) return <p>...Loading</p>;
    if (!called) {
      loadCollection();
    }
  }, [collection]);

  /**
   * Handle toggle Featured Collection Image on/off
   */
  const handleToggleCollectionImage = () => {
    if (!isCollectionImage) {
      setCollectionImage({
        variables: { collectionId: collection.id, workId },
      });
    } else {
      setIsHelperMessageVisible(true);
    }
  };

  if (loading) return null;
  if (error)
    return (
      <p className="noticiation is-danger">
        Error loading collections: {error}
      </p>
    );

  return (
    <div className="box content" data-testid="collection-box">
      <h3>Collection</h3>
      <UIFormField label="Collection">
        {isEditing ? (
          <UIFormSelect
            isReactHookForm
            name="collection"
            label="Collection"
            showHelper={true}
            options={
              collectionsData &&
              sortItemsArray(collectionsData.collections, "title").map(
                (collection) => ({
                  id: collection.id,
                  value: collection.id,
                  label: collection.title,
                })
              )
            }
            defaultValue={collection ? collection.id : ""}
            data-testid="collection-select"
          />
        ) : (
          <p>
            {collection ? (
              <Button
                className="button is-text"
                onClick={() => handleViewAllWorksClick(collection.title)}
                data-testid="view-collection-works-button"
              >
                {collection.title}
              </Button>
            ) : (
              "Not part of a collection"
            )}
          </p>
        )}
      </UIFormField>

      {!isEditing && Boolean(collection) && (
        <AuthDisplayAuthorized level="EDITOR">
          <div className="field mt-5">
            <input
              id={`featured-image-toggle`}
              type="checkbox"
              name={`featured-image-toggle`}
              className="switch"
              checked={isCollectionImage}
              onChange={handleToggleCollectionImage}
              data-testid="featured-image-toggle"
            />
            <label htmlFor={`featured-image-toggle`}>Collection image</label>
          </div>
          {isHelperMessageVisible && (
            <Notification isWarning className="is-flex is-align-items-center">
              <IconAlert />
              <span className="ml-3">
                To select a new featured image for the Collection, please
                navigate to the new Work.
              </span>
            </Notification>
          )}
        </AuthDisplayAuthorized>
      )}
    </div>
  );
}

WorkTabsAdministrativeCollection.propTypes = {
  collection: PropTypes.object,
  handleViewAllWorksClick: PropTypes.func,
  isEditing: PropTypes.bool,
  workId: PropTypes.string,
};

export default WorkTabsAdministrativeCollection;
