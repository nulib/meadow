import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import useIsEditing from "../../../hooks/useIsEditing";
import { VISIBILITY_OPTIONS } from "../../../services/global-vars";
import { useForm } from "react-hook-form";

const WorkTabsAdministrative = ({ work }) => {
  const [isEditing, setIsEditing] = useIsEditing();
  const { register, handleSubmit } = useForm();

  const onSubmit = data => {
    console.log("data", data);
  };

  return (
    <form name="work-administrative-form" onSubmit={handleSubmit(onSubmit)}>
      <div className="columns is-centered">
        <div className="column is-two-thirds">
          <div className="box">
            <div className="field">
              <label className="label">Visibility</label>
              <div className="control">
                {isEditing ? (
                  <div className="select">
                    <select
                      ref={register}
                      name="visibility"
                      defaultValue={work.visibility}
                    >
                      <option value="">Select option</option>
                      {VISIBILITY_OPTIONS.map(({ label, value }) => (
                        <option key={value} value={value}>
                          {`${value} (${label})`}
                        </option>
                      ))}
                    </select>
                  </div>
                ) : (
                  <p
                    className={`tag ${
                      work.visibility === "RESTRICTED"
                        ? "is-danger"
                        : "is-success"
                    }`}
                  >
                    {work.visibility}
                  </p>
                )}
              </div>
            </div>

            <div className="field">
              <label className="label">Collection</label>
              <div className="control">
                {isEditing ? (
                  <div className="select">
                    <select ref={register} name="collection">
                      <option>Select dropdown</option>
                      <option>With options</option>
                    </select>
                  </div>
                ) : (
                  <p>
                    {work.collection
                      ? work.collection.name
                      : "Not part of a collection"}
                  </p>
                )}
              </div>
            </div>

            <div className="field">
              <label className="label">Themes</label>
              <div className="control">
                {isEditing ? (
                  <div className="select">
                    <select ref={register} name="themes">
                      <option>Select dropdown</option>
                      <option>With options</option>
                    </select>
                  </div>
                ) : (
                  <p>Themes go here</p>
                )}
              </div>
            </div>

            <div className="field">
              <label className="label">Preservation Level</label>
              <div className="control">
                {isEditing ? (
                  <div className="select">
                    <select ref={register} name="preservationLevel">
                      <option value="1">Level 1</option>
                      <option value="2">Level 2</option>
                      <option value="3">Level 3</option>
                    </select>
                  </div>
                ) : (
                  <p>Preservation levels</p>
                )}
              </div>
            </div>
          </div>
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

WorkTabsAdministrative.propTypes = {
  work: PropTypes.object
};

export default WorkTabsAdministrative;
