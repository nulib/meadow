import React, { useState, useEffect } from "react";
import { useHistory } from "react-router-dom";
import { useMutation } from "@apollo/client";
import {
  CREATE_COLLECTION,
  UPDATE_COLLECTION,
  GET_COLLECTIONS,
} from "./collection.gql.js";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { toastWrapper } from "../../services/helpers";
import { useForm, FormProvider } from "react-hook-form";
import UIFormField from "../UI/Form/Field.jsx";
import UIFormInput from "../UI/Form/Input.jsx";
import UIFormTextarea from "../UI/Form/Textarea.jsx";
import UIFormSelect from "../UI/Form/Select.jsx";
import UITagNotYetSupported from "../UI/TagNotYetSupported";
import { Button } from "@nulib/admin-react-components";
import { COLLECTION_TYPES } from "../../services/global-vars";
import { DisplayAuthorized } from "@js/components/Auth/DisplayAuthorized";

const CollectionForm = ({ collection }) => {
  const history = useHistory();
  const [pageLoading, setPageLoading] = useState(true);
  // TODO: Fix this, put it somewhere better or refactor its implementation
  useEffect(() => {
    setPageLoading(false);
  }, []);
  const methods = useForm();
  const [createCollection, { loading, error, data }] = useMutation(
    CREATE_COLLECTION,
    {
      onCompleted({ createCollection }) {
        toastWrapper(
          "is-success",
          `Collection ${createCollection.title} created successfully`
        );
        history.push("/collection/list");
      },
      onError({ error }) {
        console.log("onError() error :>> ", error);
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
        `Collection ${updateCollection.title} updated successfully`
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
    <FormProvider {...methods}>
      <form
        onSubmit={methods.handleSubmit(onSubmit)}
        data-testid="collection-form"
      >
        <div className="field">
          <div className="control">
            <input
              type="checkbox"
              id="featured"
              ref={methods.register}
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

        <UIFormField label="Collection Title" required>
          <UIFormInput
            isReactHookForm
            placeholder="Add collection Title"
            required
            name="collectionTitle"
            label="Collection Title"
            defaultValue={collection ? collection.title : ""}
            data-testid="input-collection-title"
          />
        </UIFormField>

        <UIFormField label="Collection Type">
          <UIFormSelect
            isReactHookForm
            name="collectionType"
            label="Collection Type"
            options={COLLECTION_TYPES}
            defaultValue={collection ? collection.collectionType : ""}
            data-testid="input-collection-type"
          />
          <UITagNotYetSupported label="Display not yet supported" />
          <UITagNotYetSupported label="Update not yet supported" />{" "}
        </UIFormField>

        <UIFormField label="Description">
          <UIFormTextarea
            isReactHookForm
            name="description"
            label="Description"
            defaultValue={collection ? collection.description : ""}
            rows="6"
            data-testid="textarea-description"
          />
        </UIFormField>

        <UIFormField label="Finding Aid URL">
          <UIFormInput
            isReactHookForm
            name="findingAidUrl"
            defaultValue={collection ? collection.findingAidUrl : ""}
            label="Finding Aid Url"
            data-testid="input-finding-aid-url"
          />
        </UIFormField>

        <UIFormField label="Admin Email">
          <UIFormInput
            isReactHookForm
            name="adminEmail"
            defaultValue={collection ? collection.adminEmail : ""}
            type="email"
            label="Admin Email"
            data-testid="input-admin-email"
          />
        </UIFormField>

        <UIFormField label="Keywords">
          <UIFormInput
            isReactHookForm
            name="keywords"
            defaultValue={collection ? collection.keywords : ""}
            label="Keywords"
            data-testid="input-keywords"
          />
          <p className="help">multiple, separated, by, commas</p>
        </UIFormField>

        <DisplayAuthorized action="edit">
          <div className="buttons is-left">
            <Button type="submit" isPrimary data-testid="button-save">
              Save
            </Button>
            <Button isText data-testid="button-cancel" onClick={handleCancel}>
              Cancel
            </Button>
          </div>
        </DisplayAuthorized>
      </form>
    </FormProvider>
  );
};

export default CollectionForm;
