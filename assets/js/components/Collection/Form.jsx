import React, { useState, useEffect } from "react";
import { useHistory } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import input from "../UI/Form/Input";
import {
  CREATE_COLLECTION,
  UPDATE_COLLECTION,
  GET_COLLECTIONS
} from "./collection.query.js";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { toastWrapper } from "../../services/helpers";
import { useForm } from "react-hook-form";

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
      }
    }
  );

  const [
    updateCollection,
    { loading: updateLoading, error: updateError, data: updateData }
  ] = useMutation(UPDATE_COLLECTION, {
    onCompleted({ updateCollection }) {
      toastWrapper(
        "is-success",
        `Collection ${updateCollection.name} updated successfully`
      );
      history.push(`/collection/${collection.id}`);
    }
  });

  if (error || updateError) return <Error error={error} />;
  if (loading || updateLoading) return <Loading />;
  if (pageLoading) return <Loading />;

  const handleCancel = () => {
    history.push("/collection/list");
  };

  const onSubmit = data => {
    if (!collection) {
      createCollection({
        variables: { ...data }
      });
    } else {
      updateCollection({
        variables: { ...data, collectionId: collection.id }
      });
    }
  };

  return (
    <div>
      <form onSubmit={handleSubmit(onSubmit)} data-testid="collection-form">
        <div className="columns is-centered">
          <div className="column is-half">
            <div className="field">
              <label htmlFor="collection-name" className="label">
                Collection Name
              </label>
              <div className="control">
                <input
                  placeholder="Add collection Name"
                  className={`input ${errors.collectioName ? "is-danger" : ""}`}
                  type="text"
                  ref={register({ required: true })}
                  name="collectionName"
                  id="collection-name"
                  defaultValue={collection ? collection.name : ""}
                  data-testid="input-collection-name"
                />
              </div>
            </div>

            <div className="field">
              <label htmlFor="collection-type" className="label">
                Collection Type
              </label>
              <div className="control">
                <div className="select">
                  <select
                    ref={register}
                    id="collection-type"
                    name="collectionType"
                    data-testid="input-collection-type"
                  >
                    <option>NUL Collection</option>
                    <option>NUL Theme</option>
                  </select>
                </div>
              </div>
            </div>

            <div className="field">
              <div className="control">
                <label htmlFor="featured" className="checkbox">
                  <input
                    type="checkbox"
                    id="featured"
                    ref={register}
                    name="featured"
                    data-testid="checkbox-featured"
                    defaultChecked={collection ? collection.featured : false}
                  />{" "}
                  Featured?
                </label>
              </div>
            </div>

            <div className="field">
              <p className="notification is-warning">
                TODO: Wire up [Select thumbnail]
              </p>
            </div>

            <div className="field">
              <label htmlFor="description" className="label">
                Description
              </label>
              <div className="control">
                <textarea
                  ref={register}
                  name="description"
                  id="description"
                  defaultValue={collection ? collection.description : ""}
                  className="textarea"
                  rows="8"
                  data-testid="textarea-description"
                ></textarea>
              </div>
            </div>

            <div className="field">
              <label htmlFor="finding-aid-url" className="label">
                Finding Aid URL
              </label>
              <div className="control">
                <input
                  ref={register}
                  name="findingAidUrl"
                  id="finding-aid-url"
                  className="input"
                  defaultValue={collection ? collection.findingAidUrl : ""}
                  label="Finding Aid Url"
                  data-testid="input-finding-aid-url"
                />
              </div>
            </div>

            <div className="field">
              <label htmlFor="admin-email" className="label">
                Admin Email
              </label>
              <div className="control">
                <input
                  ref={register}
                  name="adminEmail"
                  id="admin-email"
                  className="input"
                  defaultValue={collection ? collection.adminEmail : ""}
                  type="email"
                  data-testid="input-admin-email"
                />
              </div>
            </div>

            <div className="field">
              <label htmlFor="keywords" className="label">
                Keywords
              </label>
              <div className="control">
                <input
                  ref={register}
                  name="keywords"
                  id="keywords"
                  className="input"
                  defaultValue={collection ? collection.keywords : ""}
                  label="Keywords"
                  placeholder="multiple, separated, by, commas"
                  data-testid="input-keywords"
                />
              </div>
            </div>

            <div className="buttons">
              <button
                type="submit"
                className="button is-primary"
                data-testid="button-save"
              >
                Save
              </button>
              <button
                type="button"
                className="button"
                data-testid="button-cancel"
                onClick={handleCancel}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
};

export default CollectionForm;
