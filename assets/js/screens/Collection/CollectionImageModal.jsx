import React, { useState, useEffect } from "react";
import { useMutation } from "@apollo/react-hooks";
import { SET_COLLECTION_IMAGE } from "../../components/Collection/collection.query";
import { toastWrapper } from "../../services/helpers";

const CollectionImageModal = ({ collection, isModalOpen, handleClose }) => {
  const [selectedWork, setSelectedWork] = useState();
  const [filteredWorkImages, setFilteredWorkImages] = useState();
  useEffect(() => {
    setFilteredWorkImages(collection ? collection.works : []);
  }, []);

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

  let [
    setCollectionImage,
    { loading, error: mutationError, data },
  ] = useMutation(SET_COLLECTION_IMAGE, {
    onCompleted({ setCollectionImage }) {
      toastWrapper("is-success", "Collection image has been updated");
      handleClose();
    },
    onError(error) {
      console.log("Error: ", error);
    },
  });

  const setWork = (workId) => {
    setSelectedWork(workId);
    return false;
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

  return (
    <div
      className={`modal ${isModalOpen ? "is-active" : ""}`}
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
            onClick={handleClose}
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
            {filteredWorkImages &&
              filteredWorkImages.map((work) => (
                <div
                  key={work.id}
                  className="column is-half is-narrow"
                  style={selectedWork == work.id ? styles.highlightImage : {}}
                  onClick={() => {
                    setWork(work.id);
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
          <button className="button" onClick={handleClose}>
            Cancel
          </button>
        </footer>
      </div>
    </div>
  );
};

export default CollectionImageModal;
