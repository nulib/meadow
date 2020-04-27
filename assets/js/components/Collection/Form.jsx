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
  const [selectedFileset, setSelectedFileset] = useState();
  const [filteredFilesets, setFilteredFilesets] = useState();
  const [thumbnailModalOpen, setThumbnailModalOpen] = useState(false);
  const { register, handleSubmit, watch, errors } = useForm();
  useEffect(() => {
    setPageLoading(false);
    setFilteredFilesets(fileSets);
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
      return setFilteredFilesets(fileSets);
    }
    const filteredList = fileSets.filter((fileset) => {
      return fileset.metadata.label.toUpperCase().indexOf(filterValue) > -1;
    });
    setFilteredFilesets(filteredList);
  };

  const fileSets = [
    {
      id: "d34cc24d-8d0b-4518-88aa-c0515284144c",
      metadata: {
        label: "painting5.JPG",
        originalFilename: "painting5.JPG",
      },
      work: {
        representativeImage:
          "https://devbox.library.northwestern.edu:8183/iiif/2/d34cc24d-8d0b-4518-88aa-c0515284144c/square/500,500/0/default.jpg",
      },
    },
    {
      id: "0fdc86ac-fdfb-4477-9a10-47bf0e85f91d",
      metadata: {
        label: "arch.jpg",
        originalFilename: "arch.jpg",
      },
      work: {
        representativeImage:
          "https://devbox.library.northwestern.edu:8183/iiif/2/0fdc86ac-fdfb-4477-9a10-47bf0e85f91d/square/500,500/0/default.jpg",
      },
    },
    {
      id: "b5094abe-6a66-4159-8b5f-815bf885d55a",
      metadata: {
        label: "painting1.JPG",
        originalFilename: "painting1.JPG",
      },
      work: {
        representativeImage:
          "https://devbox.library.northwestern.edu:8183/iiif/2/b5094abe-6a66-4159-8b5f-815bf885d55a/square/500,500/0/default.jpg",
      },
    },
    {
      id: "e0c0825d-43bd-470f-bb95-8c0cef838b61",
      metadata: {
        label: "coffee.jpg",
        originalFilename: "coffee.jpg",
      },
      work: {
        representativeImage:
          "https://devbox.library.northwestern.edu:8183/iiif/2/e0c0825d-43bd-470f-bb95-8c0cef838b61/square/500,500/0/default.jpg",
      },
    },
    {
      id: "0f257bc5-6bde-43d5-b695-5e3f416dd83e",
      metadata: {
        label: "topanga.jpg",
        originalFilename: "topanga.jpg",
      },
      work: {
        representativeImage:
          "https://devbox.library.northwestern.edu:8183/iiif/2/0f257bc5-6bde-43d5-b695-5e3f416dd83e/square/500,500/0/default.jpg",
      },
    },
  ];
  const works = {
    id: "8193a630-7f69-4d8f-8668-7031cf89a553",
    fileSets: fileSets,
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
    if (!selectedFileset) {
      toastWrapper("is-danger", `Please select an image to add to collection`);

      return false;
    }
    //setWorkImage
    //setCollectionImage

    setCollectionImage({
      variables: { collectionId: collection.id, workId: works.id },
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
              {filteredFilesets.map((fileset, index) => (
                <div
                  key={index}
                  className="column is-half is-narrow"
                  style={
                    selectedFileset == fileset.id ? styles.highlightImage : {}
                  }
                  onClick={() => {
                    setSelectedFileset(fileset.id);
                  }}
                >
                  <figure style={{ width: "250px", height: "250px" }}>
                    <p className="image is-square">
                      <img src={fileset.work.representativeImage} />
                    </p>
                  </figure>
                  <h2>{fileset.metadata.label}</h2>
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
      <form onSubmit={handleSubmit(onSubmit)} data-testid="collection-form">
        <div className="columns">
          <div className="column is-two-thirds">
            <div className="field">
              <div className="control">
                <article className="media" data-testid="collection-image">
                  <figure className="media-left">
                    <p
                      className="image is-square"
                      style={{ width: "200px", height: "200px" }}
                    >
                      <img
                        src={`${collection.representativeImage}/square/500,500/0/default.jpg`}
                      />
                    </p>
                  </figure>
                  <div className="media-right" style={{ marginTop: "auto" }}>
                    <button
                      data-testid="button-collection-image"
                      type="button"
                      className="button "
                      onClick={() => setThumbnailModalOpen(true)}
                    >
                      Choose Thumbnail
                    </button>
                  </div>
                </article>
              </div>
              <p className="help">Image for the Collection</p>
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
    </div>
  );
};

export default CollectionForm;
