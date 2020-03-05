import React, { useContext, useState } from "react";
import PropTypes from "prop-types";
import { IIIFContext } from "../../IIIF/IIIFProvider";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import useIsEditing from "../../../hooks/useIsEditing";
import { useForm } from "react-hook-form";
import { useMutation } from "@apollo/react-hooks";
import { SET_WORK_IMAGE } from "../work.query";
import { toastWrapper } from "../../../services/helpers";

const parseWorkRepresentativeImage = work => {
  if (!work.representativeImage) return;
  const arr = work.representativeImage.split("/");
  return arr[arr.length - 1];
};

const WorkTabsStructure = ({ work }) => {
  const [isEditing, setIsEditing] = useIsEditing();
  const [workImageFilesetId, setWorkImageFilesetId] = useState(
    parseWorkRepresentativeImage(work)
  );
  const { register, handleSubmit, errors } = useForm();
  const iiifServerUrl = useContext(IIIFContext);

  const [setWorkImage] = useMutation(SET_WORK_IMAGE, {
    onCompleted({ setWorkImage }) {
      toastWrapper("is-success", "Work image has been updated");
    }
  });

  if (!work) {
    return null;
  }

  const handleWorkImageChange = id => {
    if (id === workImageFilesetId) return;

    setWorkImageFilesetId(id === workImageFilesetId ? null : id);
    setWorkImage({ variables: { fileSetId: id, workId: work.id } });
  };

  const onSubmit = data => {
    // TODO : add logic to update filesets for given work.
    console.log(data);
  };

  return (
    <form name="work-structure-form" onSubmit={handleSubmit(onSubmit)}>
      <div className="columns is-centered">
        <div className="column is-two-thirds box">
          {work.fileSets.map(({ id, accessionNumber, metadata }) => (
            <article key={id} className="media">
              <figure className="media-left">
                <p className="image is-128x128">
                  <img
                    src={`${iiifServerUrl}${id}/square/500,500/0/default.jpg`}
                    placeholder="Fileset Image"
                  />
                </p>
              </figure>
              <div className="media-content">
                <div className="content">
                  <p>
                    <span className="tag is-medium">
                      Accession Number: {accessionNumber}
                    </span>
                  </p>

                  <div className="field">
                    <label className="label">Label</label>
                    <div className="control">
                      {isEditing ? (
                        <input
                          ref={register({ required: true })}
                          name={`label-${id}`}
                          data-testid="input-label"
                          className={`input ${
                            errors[`label-${id}`] ? "is-danger" : ""
                          }`}
                          type="text"
                          placeholder="Label"
                          defaultValue={metadata.label}
                        />
                      ) : (
                        <p>{metadata.label}</p>
                      )}
                    </div>
                    {errors[`label-${id}`] && (
                      <p className="help is-danger">Label is required</p>
                    )}
                  </div>

                  <div className="field">
                    <label className="label">Description</label>
                    <div className="control">
                      {isEditing ? (
                        <textarea
                          ref={register({ required: true })}
                          name={`metadataDescription-${id}`}
                          data-testid="textarea-metadata-description"
                          className={`input ${
                            errors[`metadataDescription-${id}`]
                              ? "is-danger"
                              : ""
                          }`}
                          defaultValue={metadata.description}
                          type="text"
                        ></textarea>
                      ) : (
                        <p>{metadata.description}</p>
                      )}
                    </div>
                    {errors[`metadataDescription-${id}`] && (
                      <p className="help is-danger">
                        Metadata Description is required
                      </p>
                    )}
                  </div>
                </div>
              </div>
              <div className="media-right has-text-right">
                {isEditing ? (
                  ""
                ) : (
                  <>
                    <div className="field">
                      <input
                        id={`checkbox-work-switch-${id}`}
                        type="checkbox"
                        name={`checkbox-work-switch-${id}`}
                        className="switch"
                        checked={workImageFilesetId === id}
                        onChange={e => handleWorkImageChange(id)}
                      />
                      <label htmlFor={`checkbox-work-switch-${id}`}>
                        Work image
                      </label>
                    </div>
                    <div className="field has-addons">
                      <p className="control">
                        <button className="button">
                          <span className="icon">
                            <FontAwesomeIcon icon="file-download" />
                          </span>{" "}
                          <span>TIFF</span>
                        </button>
                      </p>
                      <p className="control">
                        <button className="button">
                          <span className="icon">
                            <FontAwesomeIcon icon="file-download" />
                          </span>{" "}
                          <span>JPG</span>
                        </button>
                      </p>
                    </div>
                  </>
                )}
              </div>
            </article>
          ))}

          <section
            className="section has-background-light"
            style={{ marginTop: "1rem" }}
          >
            <h2 className="small-title">Download all files as zip</h2>
            <div className="columns">
              <div className="column">
                <div className="control">
                  <label className="radio">
                    <input type="radio" name="downloadsize" /> Full size
                  </label>
                  <label className="radio">
                    <input type="radio" name="downloadsize" /> 3000x3000
                  </label>
                  <label className="radio">
                    <input type="radio" name="downloadsize" /> 1000x1000
                  </label>
                </div>
              </div>

              <div className="column buttons has-text-right">
                <button className="button">Download Tiffs</button>
                <button className="button is-primary">Download JPGs</button>
              </div>
            </div>
          </section>
        </div>
        <div className="column is-narrow">
          <div className="buttons is-right">
            {!isEditing && (
              <button
                type="button"
                className="button is-primary"
                onClick={() => setIsEditing(true)}
              >
                Edit
              </button>
            )}
            {isEditing && (
              <>
                <button type="submit" className="button is-primary">
                  Save
                </button>
                <button
                  type="button"
                  className="button is-text"
                  onClick={() => setIsEditing(false)}
                >
                  Cancel
                </button>
              </>
            )}
          </div>
        </div>
      </div>
    </form>
  );
};

WorkTabsStructure.propTypes = {
  work: PropTypes.object
};

export default WorkTabsStructure;
