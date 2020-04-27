import React, { useState, useEffect } from "react";
import { useHistory } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import input from "../UI/Form/Input";
import {
  CREATE_COLLECTION,
  UPDATE_COLLECTION,
  GET_COLLECTIONS,
  SET_COLLECTION_IMAGE,
} from "./collection.query.js";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { toastWrapper } from "../../services/helpers";
import { useForm } from "react-hook-form";

const CollectionForm = ({ collection }) => {
  const history = useHistory();
  const [pageLoading, setPageLoading] = useState(true);
  const [selectedWork, setSelectedWork] = useState();
  const [filteredWorkImages, setFilteredWorkImages] = useState();
  const [thumbnailModalOpen, setThumbnailModalOpen] = useState(false);
  const { register, handleSubmit, watch, errors } = useForm();
  useEffect(() => {
    setPageLoading(false);
    setFilteredWorkImages(collection ? collection.works : []);
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

  const handleFilterChange = (e) => {
    const filterValue = e.target.value.toUpperCase();
    if (!filterValue) {
      return setFilteredWorkImages(collection ? collection.works : []);
    }
    const filteredList = collection.works.filter((work) => {
      return (
        work.descriptiveMetadata.title.toUpperCase().indexOf(filterValue) > -1
      );
    });
    setFilteredWorkImages(filteredList);
  };

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

  const [setCollectionImage] = useMutation(SET_COLLECTION_IMAGE, {
    onCompleted({ setCollectionImage }) {
      toastWrapper("is-success", "Collection image has been updated");
      history.push(`/collection/${collection.id}`);
    },
  });

  if (error || updateError) return <Error error={error} />;
  if (loading || updateLoading) return <Loading />;
  if (pageLoading) return <Loading />;

  const handleCancel = () => {
    history.push("/collection/list");
  };

  const handleThumbnailChange = () => {
    if (!selectedWork) {
      toastWrapper("is-danger", `Please select an image to add to collection`);

      return false;
    }
    setCollectionImage({
      variables: { collectionId: collection.id, workId: selectedWork },
    });
  };

  const styles = { highlightImage: { border: "10px solid #4e2a84 " } };

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
        <div className="columns">
          <div className="column is-two-thirds">
            <div className="field">
              <div className="control">
                <article className="media">
                  <figure className="media-left">
                    <p
                      className="image is-square"
                      style={{ width: "200px", height: "200px" }}
                    >
                      <img
                        data-testid="collection-image"
                        src={`${
                          collection && collection.representativeImage != null
                            ? collection.representativeImage +
                              "/square/500,500/0/default.jpg"
                            : "/images/480x480.png"
                        }`}
                      />
                    </p>
                  </figure>
                  <div
                    className="media-right"
                    style={{ marginTop: "auto" }}
                  ></div>
                </article>
              </div>
              <p className="help">Image for the collection</p>
            </div>
            <div className="field">
              <div className="control">
                <button
                  data-testid="button-open-image-modal"
                  type="button"
                  className="button is-primary is-light"
                  onClick={() => setThumbnailModalOpen(true)}
                >
                  Choose Representative Image
                </button>
              </div>
            </div>

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
              <p className="help">Name of the Collection</p>
            </div>
          </div>
          <div className="column is-one-third has-text-right">
            <div className="field is-inline-block">
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
          <p className="help">Type of Collection</p>
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
          <p className="help">Describe the Collection</p>
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
              type="text"
              defaultValue={collection ? collection.findingAidUrl : ""}
              label="Finding Aid Url"
              data-testid="input-finding-aid-url"
            />
          </div>
          <p className="help">Finding Aid URL for the Collection</p>
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
          <p className="help">Email of the Admin for this Collection</p>
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

        <div className="buttons is-right">
          <button
            type="button"
            className="button is-text"
            data-testid="button-cancel"
            onClick={handleCancel}
          >
            Cancel
          </button>
          <button
            type="submit"
            className="button is-primary"
            data-testid="button-save"
          >
            Save
          </button>
        </div>
      </form>
      <div
        className={`modal ${thumbnailModalOpen ? "is-active" : ""}`}
        data-testid="modal-collection-thumbnail"
      >
        <div className="modal-background"></div>
        <div className="modal-card">
          <header className="modal-card-head">
            <p className="modal-card-title">
              Representative Image for Collection
            </p>
            <button
              className="delete"
              aria-label="close"
              onClick={() => setThumbnailModalOpen(false)}
            ></button>
          </header>
          <section className="modal-card-body">
            <div className="control">
              <input
                className="input"
                onChange={handleFilterChange}
                placeholder="Filter collections"
                data-testid="input-collection-filter"
              />
            </div>
            <div className="section columns is-multiline">
              {filteredWorkImages.map((work) => (
                <div
                  key={work.id}
                  className="column is-half is-narrow"
                  style={selectedWork == work.id ? styles.highlightImage : {}}
                  onClick={() => {
                    setSelectedWork(work.id);
                  }}
                >
                  <figure style={{ width: "250px", height: "250px" }}>
                    <p className="image is-square">
                      <img
                        src={
                          work && work.representativeImage != null
                            ? work.representativeImage +
                              "/square/500,500/0/default.jpg"
                            : "/images/480x480.png"
                        }
                      />
                    </p>
                  </figure>
                  <h2>
                    {work.descriptiveMetadata
                      ? work.descriptiveMetadata.title
                      : work.accessionNumber}
                  </h2>
                </div>
              ))}
            </div>
          </section>
          <footer className="modal-card-foot">
            <button
              className="button is-primary"
              onClick={() => {
                handleThumbnailChange();
              }}
              data-testid="button-set-image"
            >
              Set Image
            </button>
            <button
              className="button"
              onClick={() => setThumbnailModalOpen(false)}
            >
              Cancel
            </button>
          </footer>
        </div>
      </div>
    </div>
  );
};

export default CollectionForm;
