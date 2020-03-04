import React, { useContext } from "react";
import PropTypes from "prop-types";
import { IIIFContext } from "../../IIIF/IIIFProvider";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import useIsEditing from "../../../hooks/useIsEditing";
import { useForm } from "react-hook-form";

const WorkTabsStructure = ({ work }) => {
  const [isEditing, setIsEditing] = useIsEditing();
  const { register, handleSubmit, errors } = useForm();
  const iiifServerUrl = useContext(IIIFContext);

  if (!work) {
    return null;
  }

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
                <p className="image is-64x64">
                  <img
                    src={`${iiifServerUrl}${id}/square/500,500/0/default.jpg`}
                    placeholder="Fileset Image"
                    onError={e => {
                      e.target.src = "/images/1280x960.png";
                    }}
                  />
                </p>
              </figure>
              <div className="media-content">
                <div className="content">
                  {isEditing ? (
                    <>
                      <div className="field">
                        <strong>{accessionNumber}</strong>
                      </div>
                      <div className="field">
                        <div class="field is-horizontal">
                          <div class="field-label is-normal">
                            <label class="label">Label</label>
                          </div>
                          <div class="field-body">
                            <div class="field">
                              <p class="control">
                                <input
                                  ref={register({ required: true })}
                                  name={`label-${id}`}
                                  data-testid="label"
                                  className={`input ${
                                    errors[`label-${id}`] ? "is-danger" : ""
                                  }`}
                                  type="text"
                                  placeholder="Label"
                                  defaultValue={metadata.label}
                                />
                              </p>
                              {errors[`label-${id}`] && (
                                <p className="help is-danger">
                                  Label is required
                                </p>
                              )}
                            </div>
                          </div>
                        </div>
                      </div>

                      <div className="field">
                        <div class="field is-horizontal">
                          <div class="field-label is-normal">
                            <label class="label">Description</label>
                          </div>
                          <div class="field-body">
                            <div class="field">
                              <p class="control">
                                <textarea
                                  ref={register({ required: true })}
                                  name={`metadataDescription-${id}`}
                                  data-testid="metadataDescription"
                                  className={`input ${
                                    errors[`metadataDescription-${id}`]
                                      ? "is-danger"
                                      : ""
                                  }`}
                                  defaultValue={metadata.description}
                                  type="text"
                                ></textarea>
                              </p>
                              {errors[`metadataDescription-${id}`] && (
                                <p className="help is-danger">
                                  Metadata Description is required
                                </p>
                              )}
                            </div>
                          </div>
                        </div>
                      </div>
                    </>
                  ) : (
                    <p>
                      <strong>{accessionNumber}</strong>
                      <br />
                      {metadata.label}
                      <br />
                      {metadata.description}
                    </p>
                  )}
                </div>
              </div>
              {isEditing ? (
                ""
              ) : (
                <div className="media-right">
                  <button className="button">
                    <FontAwesomeIcon icon="file-download" /> .tiff
                  </button>
                  <button className="button">
                    <FontAwesomeIcon icon="file-download" /> .jpg
                  </button>
                </div>
              )}
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
                  className="button"
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
