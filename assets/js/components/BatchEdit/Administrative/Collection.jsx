import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import { GET_COLLECTIONS } from "@js/components/Collection/collection.gql";
import { useFormContext } from "react-hook-form";
import { useQuery } from "@apollo/client";

function BatchEditCollection() {
  const context = useFormContext();
  const register = context.register;

  const {
    loading: collectionLoading,
    error: collectionError,
    data: collectionData,
  } = useQuery(GET_COLLECTIONS);

  if (collectionError) {
    return <p className="notification is-danger">Error loading Collections</p>;
  }
  if (collectionLoading) {
    return null;
  }

  return (
    <UIFormField label="Collection">
      <div className="select">
        <select name="collection" ref={register()} data-testid="collection">
          <option value="">-- Select --</option>
          {collectionData &&
            collectionData.collections.map(({ id, title }) => (
              <option key={id} value={JSON.stringify({ id, title })}>
                {title}
              </option>
            ))}
        </select>
      </div>
    </UIFormField>
  );
}

BatchEditCollection.propTypes = {};

export default BatchEditCollection;
