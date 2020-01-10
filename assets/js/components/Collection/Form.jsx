import React, { useState, useEffect } from "react";
import { useHistory } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import UIButton from "../UI/Button";
import UIButtonGroup from "../UI/ButtonGroup";
import UIFormInput from "../UI/Form/Input";
import UISelect from "../UI/Select";
import UIDivider from "../UI/Divider";
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
    collectionName: obj.name || "",
    collectionType: "",
    isFeatured: false,
    description: "",
    findingAidUrl: "",
    adminEmail: "",
    keywords: null
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
  const [formValues, setFormValues] = useState({});
  const { addToast } = useToasts();
  const [submitDisabled, setSubmitDisabled] = useState(true);

  useEffect(() => {
    setSubmitDisabled(
      formValues.collectionName === "" || formValues.collectionType === ""
    );
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
    const prevVal = formValues.isFeatured;
    setFormValues({
      ...formValues,
      isFeatured: !prevVal
    });
  };

  const handleSubmit = e => {
    e.preventDefault();

    // Convert keywords to an array as defined in GraphQL
    let values = { ...formValues };
    values.keywords = formValues.keywords
      .split(",")
      .map(keyword => keyword.trim());

    console.log("submitted form values :", values);
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
        <section className="flex justify-between items-center">
          <div className="w-1/2 form-group">
            <UIFormInput
              placeholder="Add collection Name"
              type="text"
              // Using "collectionName" instead of GraphQL schema's "name" because
              // browsers keep autofilling with personal names "ie. Adam J. Arling"
              name="collectionName"
              label="Collection Name"
              value={formValues.collectionName}
              onChange={handleInputChange}
            />
          </div>
          <div className="form-group">
            <input
              type="checkbox"
              id="isFeatured"
              name="isFeatured"
              onChange={handleIsFeaturedChange}
            />
            <label htmlFor="isFeatured" className="inline-block ml-2">
              Featured?
            </label>
          </div>
        </section>
        <section className="sm:w-full md:w-2/3">
          <div className="form-group">
            <UISelect
              options={[
                {
                  label: "Collection type...",
                  value: ""
                },
                {
                  label: "NUL Collection",
                  value: "NUL Collection"
                },
                {
                  label: "NUL Theme",
                  value: "NUL Theme"
                }
              ]}
              value={formValues.collectionType}
              name="collectionType"
              onChange={handleInputChange}
              className="shadow"
            ></UISelect>
          </div>
          <div className="form-group">
            <p>[Select thumbnail]</p>
          </div>
          <div className="form-group">
            <label htmlFor="description">Description</label>
            <textarea
              name="description"
              id="description"
              onChange={handleInputChange}
              value={formValues.description}
              className="text-input w-full"
              rows="8"
            >
              {formValues.description}
            </textarea>
          </div>
          <div className="form-group">
            <UIFormInput
              name="findingAidUrl"
              id="findingAidUrl"
              onChange={handleInputChange}
              value={formValues.findingAidUrl}
              label="Finding Aid Url"
            />
          </div>
          <UIDivider />
          <div className="form-group">
            <UIFormInput
              name="adminEmail"
              id="adminEmail"
              value={formValues.adminEmail}
              onChange={handleInputChange}
              label="Admin Email Address"
              type="email"
            />
          </div>
          <UIDivider />
          <div className="form-group">
            <UIFormInput
              name="keywords"
              id="keywords"
              value={formValues.keywords}
              onChange={handleInputChange}
              label="Keywords"
              placeholder="multiple, separated, by, commas"
            />
          </div>
        </section>
        <UIButtonGroup>
          <UIButton type="submit" disabled={submitDisabled}>
            Submit
          </UIButton>
          <UIButton className="btn-clear" onClick={handleCancel}>
            Cancel
          </UIButton>
        </UIButtonGroup>
      </form>
    </div>
  );
};

export default CollectionForm;
