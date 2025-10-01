import React from "react";
import UIFormField from "@js/components/UI/Form/Field";
import { GET_COLLECTIONS } from "@js/components/Collection/collection.gql";
import { useFormContext } from "react-hook-form";
import { useQuery } from "@apollo/client/react";
import { sortItemsArray } from "@js/services/helpers";
import { Notification } from "@nulib/design-system";

function BatchEditCollection() {
  const context = useFormContext();
  const register = context.register;

  const {
    loading: collectionLoading,
    error: collectionError,
    data: collectionData,
  } = useQuery(GET_COLLECTIONS);

  if (collectionError) {
    return <Notification isDanger>Error loading Collections</Notification>;
  }
  if (collectionLoading) {
    return null;
  }

  return (
    <UIFormField label="Collection">
      <div className="select">
        <select {...register("collection")} data-testid="collection">
          <option value="">-- Select --</option>
          {collectionData &&
            sortItemsArray(collectionData.collections, "title").map(
              ({ id, title }) => (
                <option
                  key={id}
                  data-testid="select-option"
                  value={JSON.stringify({ id, title })}
                >
                  {title}
                </option>
              )
            )}
        </select>
      </div>
    </UIFormField>
  );
}

BatchEditCollection.propTypes = {};

export default BatchEditCollection;
