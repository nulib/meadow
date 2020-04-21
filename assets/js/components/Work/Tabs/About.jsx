import React, { useState } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { toastWrapper } from "../../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useForm } from "react-hook-form";
import { useMutation } from "@apollo/react-hooks";
import useIsEditing from "../../../hooks/useIsEditing";
import { UPDATE_WORK } from "../work.query";
import UITagNotYetSupported from "../../UI/TagNotYetSupported";

const WorkTabsAbout = ({ work }) => {
  const { descriptiveMetadata } = work;
  const [showCoreMetadata, setShowCoreMetadata] = useState(true);
  const [showDescriptiveMetadata, setShowDescriptiveMetadata] = useState(true);
  const { register, handleSubmit, watch, errors } = useForm();
  const [isEditing, setIsEditing] = useIsEditing();

  const [updateWork] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      toastWrapper("is-success", "Work form has been updated");
    }
  });

  const onSubmit = data => {
    const { description = "", title = "" } = data;
    let workUpdateInput = {
      descriptiveMetadata: {
        title,
        description
      },
      published: true
    };

    setIsEditing(false);
    updateWork({
      variables: { id: work.id, work: workUpdateInput }
    });
  };

  return (
    <form name="work-about-form" onSubmit={handleSubmit(onSubmit)}>
      <div className="columns is-centered">
        <div className="column is-two-thirds">
          <h2 className="title is-size-5">
            Core Metadata{" "}
            <a onClick={() => setShowCoreMetadata(!showCoreMetadata)}>
              <FontAwesomeIcon
                icon={
                  showCoreMetadata
                    ? "chevron-circle-down"
                    : "chevron-circle-right"
                }
              />
            </a>
          </h2>
          {showCoreMetadata && (
            <div className="box is-shadowless">
              <div className="field">
                <label className="label">Title</label>
                <div className="control">
                  {isEditing ? (
                    <>
                      <input
                        ref={register({ required: true })}
                        name="title"
                        className={`input ${errors.title ? "is-danger" : ""}`}
                        data-testid="title"
                        placeholder="e.g. Best work ever"
                        defaultValue={descriptiveMetadata.title}
                      />
                      {errors.description && (
                        <p className="help is-danger">
                          Title field is required
                        </p>
                      )}
                    </>
                  ) : (
                    <p>{descriptiveMetadata.title || "No title provided"}</p>
                  )}
                </div>
              </div>
              <div className="field">
                <label className="label">Description</label>
                <div className="control">
                  {isEditing ? (
                    <>
                      <textarea
                        ref={register({ required: true })}
                        name="description"
                        className={`textarea ${
                          errors.description ? "is-danger" : ""
                        }`}
                        data-testid="description"
                        placeholder="Describe the work"
                        defaultValue={descriptiveMetadata.description}
                      />
                      {errors.description && (
                        <p className="help is-danger">
                          Description field is required
                        </p>
                      )}
                    </>
                  ) : (
                    <p>
                      {descriptiveMetadata.description ||
                        "No description provided"}
                    </p>
                  )}
                </div>
              </div>
              <div className="field">
                <label className="label">
                  Date Created{" "}
                  <UITagNotYetSupported label="Display not yet supported" />
                  <UITagNotYetSupported label="Update not yet supported" />
                </label>
                <div className="control">
                  {isEditing ? (
                    <>
                      <input
                        ref={register}
                        name="dateCreated"
                        data-testid="date-created"
                        className={`input ${
                          errors.dateCreated ? "is-danger" : ""
                        }`}
                      />
                      {errors.dateCreated && (
                        <p className="help is-danger">
                          Date Created field is required
                        </p>
                      )}
                    </>
                  ) : (
                    <p>Date will go here</p>
                  )}
                </div>
              </div>
            </div>
          )}

          <h2 className="title is-size-5">
            Descriptive Metadata{" "}
            <a
              onClick={() =>
                setShowDescriptiveMetadata(!showDescriptiveMetadata)
              }
            >
              <FontAwesomeIcon
                icon={
                  showDescriptiveMetadata
                    ? "chevron-circle-down"
                    : "chevron-circle-right"
                }
              />
            </a>
          </h2>
          {showDescriptiveMetadata && (
            <div className="box is-shadowless">
              <div className="field">
                <label className="label">
                  Creators{" "}
                  <UITagNotYetSupported label="Display not yet supported" />{" "}
                  <UITagNotYetSupported label="Update not yet supported" />
                </label>
                <div className="control">
                  <ul>
                    <li>
                      <Link to="/">Creator 1 as a link</Link>
                    </li>
                    <li>
                      <Link to="/">Creator 2 as a link</Link>
                    </li>
                    <li>
                      <Link to="/">Creator 3 as a link</Link>
                    </li>
                  </ul>
                </div>
              </div>

              <div className="field">
                <label className="label">
                  Contributors{" "}
                  <UITagNotYetSupported label="Display not yet supported" />{" "}
                  <UITagNotYetSupported label="Update not yet supported" />
                </label>
                <ul>
                  <li>
                    <Link to="/">Contributor 1 as a link</Link>
                  </li>
                  <li>
                    <Link to="/">Contributor 2 as a link</Link>
                  </li>
                  <li>
                    <Link to="/">Contributor 3 as a link</Link>
                  </li>
                </ul>
              </div>
            </div>
          )}
        </div>
        <div className="column is-narrow">
          <div className="buttons">
            {!isEditing && (
              <button
                type="button"
                className="button is-primary"
                data-testid="edit-button"
                onClick={() => setIsEditing(true)}
              >
                Edit
              </button>
            )}
            {isEditing && (
              <>
                <button
                  type="submit"
                  className="button is-primary"
                  data-testid="save-button"
                >
                  Save
                </button>
                <button
                  type="button"
                  className="button is-text"
                  data-testid="cancel-button"
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

WorkTabsAbout.propTypes = {
  work: PropTypes.object
};

export default WorkTabsAbout;
