import React, { useState, useEffect } from "react";
import { useHistory } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import UIButton from "../UI/Button";
import UIButtonGroup from "../UI/ButtonGroup";
import UIFormInput from "../UI/Form/Input";
import {
  CREATE_COLLECTION,
  UPDATE_COLLECTION,
  GET_COLLECTIONS
} from "./collection.query.js";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { useToasts } from "react-toast-notifications";

// Pass in existing collection values when editing
function setInitialFormValues(obj = {}) {
  const initialFormValues = {
    collectionName: obj.name || ""
  };
  let values = {
    ...initialFormValues,
    ...obj
  };

  delete values.name;
  delete values.keywords;
  values.keywords =
    obj.keywords && obj.keywords.length > 0 ? obj.keywords.join(", ") : "";

  return values;
}

const CollectionForm = ({ collection }) => {
  const history = useHistory();
  const [pageLoading, setPageLoading] = useState(true);
  const [submitDisabled, setSubmitDisabled] = useState(true);
  const [formValues, setFormValues] = useState({});
  const { addToast } = useToasts();

  useEffect(() => {
    setSubmitDisabled(formValues.collectionName === "");
  }, [formValues]);

  useEffect(() => {
    setPageLoading(false);
    setFormValues(setInitialFormValues(collection));
  }, []);

  const [createCollection, { loading, error, data }] = useMutation(
    CREATE_COLLECTION,
    {
      onCompleted({ createCollection }) {
        addToast(`Collection ${createCollection.name} created successfully`, {
          appearance: "success",
          autoDismiss: true
        });
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
      addToast(`Collection ${updateCollection.name} updated successfully`, {
        appearance: "success",
        autoDismiss: true
      });
      history.push(`/collection/${collection.id}`);
    }
  });

  if (error || updateError) return <Error error={error} />;
  if (loading || updateLoading) return <Loading />;
  if (pageLoading) return <Loading />;

  const handleCancel = () => {
    history.push("/collection/list");
  };

  const handleInputChange = e => {
    setFormValues({
      ...formValues,
      [e.target.name]: e.target.value
    });
  };

  const handleIsFeaturedChange = e => {
    const prevVal = formValues.featured;
    setFormValues({
      ...formValues,
      featured: !prevVal
    });
  };

  const handleSubmit = e => {
    e.preventDefault();

    // Convert keywords to an array as defined in GraphQL
    let values = { ...formValues };
    values.keywords = formValues.keywords
      .split(",")
      .map(keyword => keyword.trim());

    console.log("values :", values);
    if (!collection) {
      createCollection({
        variables: { ...values }
      });
    } else {
      updateCollection({
        variables: { ...values, collectionId: collection.id }
      });
    }
  };

  return (
    <div>
      <form onSubmit={handleSubmit} data-testid="collection-form">
        <div className="columns is-centered">
          <div className="column is-half">
            <UIFormInput
              placeholder="Add collection Name"
              type="text"
              name="collectionName"
              id="collectionName"
              label="Collection Name"
              value={formValues.collectionName || ""}
              onChange={handleInputChange}
              data-testid="collection-name"
            />

            <div className="field">
              <label htmlFor="collection-type" className="label">
                Collection Type
              </label>
              <div className="control">
                <div className="select">
                  <select id="collection-type" data-testid="collection-type">
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
                    name="featured"
                    onChange={handleIsFeaturedChange}
                    data-testid="featured"
                  />{" "}
                  Featured?
                </label>
              </div>
            </div>

            <div className="field" data-testid="choose-thumbnail">
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
                  name="description"
                  id="description"
                  onChange={handleInputChange}
                  value={formValues.description || ""}
                  className="textarea"
                  rows="8"
                  data-testid="description"
                >
                  {formValues.description}
                </textarea>
              </div>
            </div>

            <UIFormInput
              name="findingAidUrl"
              id="findingAidUrl"
              onChange={handleInputChange}
              value={formValues.findingAidUrl || ""}
              label="Finding Aid Url"
              data-testid="finding-aid-url"
            />

            <UIFormInput
              name="adminEmail"
              id="adminEmail"
              value={formValues.adminEmail || ""}
              onChange={handleInputChange}
              label="Admin Email Address"
              type="email"
              data-testid="admin-email"
            />

            <UIFormInput
              name="keywords"
              id="keywords"
              value={formValues.keywords || ""}
              onChange={handleInputChange}
              label="Keywords"
              placeholder="multiple, separated, by, commas"
              data-testid="keywords"
            />
            <UIButtonGroup>
              <UIButton
                type="submit"
                className="is-primary"
                disabled={submitDisabled}
              >
                Submit
              </UIButton>
              <UIButton onClick={handleCancel}>Cancel</UIButton>
            </UIButtonGroup>
          </div>
        </div>
      </form>
    </div>
  );
};

export default CollectionForm;
