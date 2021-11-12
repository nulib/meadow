import React, { useState, useEffect } from "react";
import { useHistory } from "react-router-dom";
import { useMutation } from "@apollo/client";
import {
  CREATE_COLLECTION,
  UPDATE_COLLECTION,
  GET_COLLECTIONS,
} from "./collection.gql.js";
import Error from "../UI/Error";
import { toastWrapper } from "../../services/helpers";
import { useForm, FormProvider } from "react-hook-form";
import UIFormField from "../UI/Form/Field.jsx";
import UIFormInput from "../UI/Form/Input.jsx";
import UIFormTextarea from "../UI/Form/Textarea.jsx";
import UIFormSelect from "../UI/Form/Select.jsx";
import { Button } from "@nulib/design-system";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { useCodeLists } from "@js/context/code-list-context";
import UISkeleton from "@js/components/UI/Skeleton";

const CollectionForm = ({ collection }) => {
  const history = useHistory();
  const codeLists = useCodeLists();
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
  if (loading || updateLoading) return <UISkeleton />;

  const handleCancel = () => {
    history.push("/collection/list");
  };

  const onSubmit = (data) => {
    let currentFormValues = methods.getValues();
    let collectionUpdate = {
      ...currentFormValues,
      visibility: currentFormValues.visibility
        ? { id: currentFormValues.visibility, scheme: "VISIBILITY" }
        : {},
    };

    if (!collection) {
      createCollection({
        variables: { ...collectionUpdate },
      });
    } else {
      updateCollection({
        variables: { ...collectionUpdate, collectionId: collection.id },
      });
    }
  };

  return (
    <FormProvider {...methods}>
      <form
        onSubmit={methods.handleSubmit(onSubmit)}
        data-testid="collection-form"
      >
        <div className="is-flex is-justify-content-space-between mb-5">
          <h1 className="title" data-testid="collection-form-title">
            {collection ? "Edit" : "Add New"} Collection
          </h1>
        </div>

        <div className="columns">
          <div className="column is-two-thirds">
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

            {/* <UIFormField label="Collection Type">
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
        </UIFormField> */}

            <UIFormField label="Description">
              <UIFormTextarea
                isReactHookForm
                name="description"
                label="Description"
                defaultValue={collection ? collection.description : ""}
                rows="3"
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
          </div>

          <div className="column is-one-third">
            {/* Render when the CodeList options are ready, otherwise React Hook Form is wonky with picking up the default value */}
            {codeLists.visibilityData && (
              <UIFormField label="Visibility">
                <UIFormSelect
                  data-testid="visibility"
                  isReactHookForm
                  name="visibility"
                  label="Visibility"
                  showHelper={true}
                  options={
                    codeLists.visibilityData
                      ? codeLists.visibilityData.codeList
                      : []
                  }
                  defaultValue={
                    collection && collection.visibility
                      ? collection.visibility.id
                      : ""
                  }
                />
              </UIFormField>
            )}

            <div className="field" className="my-5">
              <div className="control">
                <input
                  type="checkbox"
                  id="featured"
                  {...methods.register("featured")}
                  className="switch"
                  data-testid="checkbox-featured"
                  defaultChecked={collection ? collection.featured : false}
                />{" "}
                <label htmlFor="featured">Featured?</label>
              </div>
            </div>

            <div className="field">
              <input
                id="published"
                type="checkbox"
                {...methods.register("published")}
                className="switch"
                data-testid="checkbox-published"
                defaultChecked={collection ? collection.published : false}
              />
              <label htmlFor="published">Published</label>
            </div>
          </div>
        </div>

        <AuthDisplayAuthorized level="MANAGER">
          <div className="buttons mt-5">
            <Button type="submit" isPrimary data-testid="button-save">
              Save
            </Button>
            <Button isText data-testid="button-cancel" onClick={handleCancel}>
              Cancel
            </Button>
          </div>
        </AuthDisplayAuthorized>
      </form>
    </FormProvider>
  );
};

export default CollectionForm;
