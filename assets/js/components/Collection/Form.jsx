import React, { useState, useEffect } from "react";
import { useHistory } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import {
  CREATE_COLLECTION,
  UPDATE_COLLECTION,
  GET_COLLECTIONS,
} from "./collection.gql.js";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { toastWrapper } from "../../services/helpers";
import { useForm } from "react-hook-form";
import UIFormField from "../UI/Form/Field.jsx";
import UIFormInput from "../UI/Form/Input.jsx";
import UIFormTextarea from "../UI/Form/Textarea.jsx";
import UIFormSelect from "../UI/Form/Select.jsx";
import UITagNotYetSupported from "../UI/TagNotYetSupported";

import { COLLECTION_TYPES } from "../../services/global-vars";

const CollectionForm = ({ collection }) => {
  const history = useHistory();
  const [pageLoading, setPageLoading] = useState(true);
  const { register, handleSubmit, watch, errors } = useForm();
  useEffect(() => {
    setPageLoading(false);
  }, []);
  const [createCollection, { loading, error, data }] = useMutation(
    CREATE_COLLECTION,
    {
      onCompleted({ createCollection }) {
        toastWrapper(
          "is-success",
          `Collection ${createCollection.name} created successfully`
        );
        history.push("/collection/list");
      },
      refetchQueries(mutationResult) {
        return [{ query: GET_COLLECTIONS }];
      },
    }
  );

  const [
    updateCollection,
    { loading: updateLoading, error: updateError, data: updateData },
  ] = useMutation(UPDATE_COLLECTION, {
    onCompleted({ updateCollection }) {
      toastWrapper(
        "is-success",
        `Collection ${updateCollection.name} updated successfully`
      );
      history.push(`/collection/${collection.id}`);
    },
  });

  if (error || updateError) return <Error error={error} />;
  if (loading || updateLoading) return <Loading />;
  if (pageLoading) return <Loading />;

  const handleCancel = () => {
    history.push("/collection/list");
  };

  const onSubmit = (data) => {
    if (!collection) {
      createCollection({
        variables: { ...data },
      });
    } else {
      updateCollection({
        variables: { ...data, collectionId: collection.id },
      });
    }
  };

  return (
    <div>
      <form onSubmit={handleSubmit(onSubmit)} data-testid="collection-form">
        <div className="field">
          <div className="control">
            <input
              type="checkbox"
              id="featured"
              ref={register}
              className="is-checkradio"
              name="featured"
              data-testid="checkbox-featured"
              defaultChecked={collection ? collection.featured : false}
            />{" "}
            <label htmlFor="featured" className="checkbox">
              Featured?
            </label>
          </div>
        </div>

        <UIFormField label="Collection Name">
          <UIFormInput
            placeholder="Add collection Name"
            register={register}
            required
            name="collectionName"
            label="Collection Name"
            errors={errors}
            defaultValue={collection ? collection.name : ""}
            data-testid="input-collection-name"
          />
        </UIFormField>

        <UIFormField label="Collection Type">
          <UIFormSelect
            register={register}
            name="collectionType"
            label="Collection Type"
            options={COLLECTION_TYPES}
            defaultValue={collection ? collection.collectionType : ""}
            errors={errors}
            data-testid="input-collection-type"
          />
          <UITagNotYetSupported label="Display not yet supported" />
          <UITagNotYetSupported label="Update not yet supported" />{" "}
        </UIFormField>

        <UIFormField label="Description">
          <UIFormTextarea
            register={register}
            errors={errors}
            name="description"
            label="Description"
            defaultValue={collection ? collection.description : ""}
            rows="8"
            data-testid="textarea-description"
          />
        </UIFormField>

        <UIFormField label="Finding Aid URL">
          <UIFormInput
            register={register}
            errors={errors}
            name="findingAidUrl"
            defaultValue={collection ? collection.findingAidUrl : ""}
            label="Finding Aid Url"
            data-testid="input-finding-aid-url"
          />
        </UIFormField>

        <UIFormField label="Admin Email">
          <UIFormInput
            register={register}
            errors={errors}
            name="adminEmail"
            defaultValue={collection ? collection.adminEmail : ""}
            type="email"
            label="Admin Email"
            data-testid="input-admin-email"
          />
        </UIFormField>

        <UIFormField label="Keywords">
          <UIFormInput
            register={register}
            name="keywords"
            errors={errors}
            defaultValue={collection ? collection.keywords : ""}
            label="Keywords"
            placeholder="multiple, separated, by, commas"
            data-testid="input-keywords"
          />
        </UIFormField>

        <div className="buttons is-left">
          <button
            type="submit"
            className="button is-primary"
            data-testid="button-save"
          >
            Save
          </button>
          <button
            type="button"
            className="button is-text"
            data-testid="button-cancel"
            onClick={handleCancel}
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
};

export default CollectionForm;
