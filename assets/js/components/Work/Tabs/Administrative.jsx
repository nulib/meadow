import React, { useContext, useState } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { WorkFormContext } from "../FormProvider";

const visibilityOptions = ["RESTRICTED", "WHAT", "ARE", "THESE"];

const WorkTabsAdministrative = ({ work }) => {
  const isEditing = useContext(WorkFormContext);
  const [visibility, setVisibility] = useState(work.visibility);

  return (
    <div
      className="columns is-centered"
      data-testid="tab-administrative-content"
    >
      <div className="column is-three-quarters">
        <div className="field">
          <label className="label">Visibility</label>
          <div className="control">
            {isEditing ? (
              <div className="select">
                <select
                  value={visibility}
                  onChange={e => setVisibility(e.target.value)}
                >
                  <option value="">Select dropdown</option>
                  {visibilityOptions.map(option => (
                    <option key={option} value={option}>
                      {option}
                    </option>
                  ))}
                </select>
              </div>
            ) : (
              <p
                className={`tag ${
                  work.visibility === "RESTRICTED" ? "is-danger" : "is-success"
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
                <select>
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
                <select>
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
                <select>
                  <option>Select dropdown</option>
                  <option>With options</option>
                </select>
              </div>
            ) : (
              <p>Preservation levels</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

WorkTabsAdministrative.propTypes = {
  work: PropTypes.object
};

export default WorkTabsAdministrative;
