import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";

const WorkTabsAdministrative = ({ work }) => {
  return (
    <div
      className="columns is-centered"
      data-testid="tab-administrative-content"
    >
      <div className="column is-three-quarters">
        <div className="box is-shadowless">
          <h3 className="small-title">Visibility</h3>
          <p
            className={`tag ${
              work.visibility === "RESTRICTED" ? "is-danger" : "is-success"
            }`}
          >
            {work.visibility}
          </p>
        </div>
        <div className="box is-shadowless">
          <h3 className="small-title">Collection</h3>
          <p>
            {work.collection
              ? work.collection.name
              : "Not part of a collection"}
          </p>
        </div>
        <div className="box is-shadowless">
          <h3 className="small-title">Themes</h3>
          <p className="notification is-warning">Need this in GraphQL</p>
        </div>
        <div className="box is-shadowless">
          <h3 className="small-title">Preservation Level</h3>
          <p>
            {work.workAdministrativeMetadata
              ? work.workAdministrativeMetadata.preservationLevel
              : "No preservation level"}
          </p>
        </div>
        <hr />
        <p className="notification is-warning">
          TODO: Need to show/hide Edit UI based on editing state
        </p>
        <h3 className="small-title">[Edit Mode]</h3>
        <div className="select">
          <select>
            <option>Select dropdown</option>
            <option>With options</option>
          </select>
        </div>
        <h3 className="small-title">Collection</h3>
        <div className="select">
          <select>
            <option>Select dropdown</option>
            <option>With options</option>
          </select>
        </div>
        <h3 className="small-title">Themes</h3>
        <div className="select">
          <select>
            <option>Select dropdown</option>
            <option>With options</option>
          </select>
        </div>
        <h3 className="small-title">Preservation Level</h3>
        <div className="select">
          <select>
            <option>Select dropdown</option>
            <option>With options</option>
          </select>
        </div>
      </div>
    </div>
  );
};

WorkTabsAdministrative.propTypes = {
  work: PropTypes.object
};

export default WorkTabsAdministrative;
