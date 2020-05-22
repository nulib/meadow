import React, { useState, useEffect } from "react";
import { useMutation } from "@apollo/react-hooks";
import { SET_COLLECTION_IMAGE } from "./collection.gql";
import { toastWrapper } from "../../services/helpers";
import UIFormInput from "../UI/Form/Input";

const CollectionImageModal = ({ collection, isModalOpen, handleClose }) => {
  const [selectedWork, setSelectedWork] = useState();
  const [filteredWorkImages, setFilteredWorkImages] = useState();
  useEffect(() => {
    setSelectedWork(
      collection.representativeWork ? collection.representativeWork.id : ""
    );
    setFilteredWorkImages(collection ? collection.works : []);
  }, []);

  const handleFilterChange = (e) => {
    const filterValue = e.target.value.toUpperCase();
    if (!filterValue) {
      return setFilteredWorkImages(collection ? collection.works : []);
    }
    const filteredList = collection.works.filter((work) => {
      return work.descriptiveMetadata.title
        ? work.descriptiveMetadata.title.toUpperCase().indexOf(filterValue) > -1
        : false;
    });
    setFilteredWorkImages(filteredList);
  };

  let [
    setCollectionImage,
    { loading, error: mutationError, data },
  ] = useMutation(SET_COLLECTION_IMAGE, {
    onCompleted({ setCollectionImage }) {
      toastWrapper("is-success", "Collection image has been updated");
      handleClose();
    },
    onError(error) {
      toastWrapper("is-danger", "Error updating collection image");
      console.log("Error updating collection image: ", error);
    },
  });

  const setWork = (workId) => {
    setSelectedWork(workId);
    return;
  };

  const handleThumbnailChange = () => {
    if (!selectedWork) {
      toastWrapper("is-danger", `Please select an image to add to collection`);
      return;
    }
    setCollectionImage({
      variables: { collectionId: collection.id, workId: selectedWork },
    });
  };

  const styles = {
    highlightImage: { outline: "5px solid #4e2a84" },
    fullWidth: { width: "85%" },
  };

  return (
    <div
      className={`modal ${isModalOpen ? "is-active" : ""}`}
      data-testid="modal-collection-thumbnail"
    >
      <div className="modal-background"></div>
      <div className="modal-card" style={styles.fullWidth}>
        <header className="modal-card-head">
          <p className="modal-card-title">
            Representative Image for Collection
          </p>
          <button
            className="modal-close is-large"
            aria-label="close"
            onClick={handleClose}
          ></button>
        </header>
        <section className="modal-card-body">
          <UIFormInput
            onChange={handleFilterChange}
            placeholder="Filter works by title"
            data-testid="input-collection-filter"
            name="collectionName"
            label="Filter works by title"
          />
          <div className="section columns is-multiline">
            {filteredWorkImages &&
              filteredWorkImages.map((work) => (
                <div
                  key={work.id}
                  className="column is-3 has-text-centered"
                  style={selectedWork == work.id ? styles.highlightImage : {}}
                  onClick={() => {
                    setWork(work.id);
                  }}
                >
                  <figure className="image is-128x128 is-inline-block">
                    <img
                      src={
                        work && work.representativeImage != null
                          ? `${work.representativeImage}/square/500,500/0/default.jpg`
                          : "/images/480x480.png"
                      }
                    />
                  </figure>
                  <p>
                    {work.descriptiveMetadata
                      ? work.descriptiveMetadata.title
                      : work.accessionNumber}
                  </p>
                </div>
              ))}
          </div>
        </section>
        <footer className="modal-card-foot buttons is-right">
          <button className="button is-text" onClick={handleClose}>
            Cancel
          </button>
          <button
            className="button is-primary"
            onClick={() => {
              handleThumbnailChange();
            }}
            data-testid="button-set-image"
          >
            Set Image
          </button>
        </footer>
      </div>
    </div>
  );
};

export default CollectionImageModal;
