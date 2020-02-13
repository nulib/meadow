import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { formatDate } from "../../../services/helpers";

const WorkTabsAbout = ({ work }) => {
  const { descriptiveMetadata } = work;
  return (
    <div className="columns is-centered" data-testid="tab-about-content">
      <div className="column is-three-quarters">
        <div className="box is-shadowless">
          <h3 className="small-title">Description</h3>
          <p>
            {descriptiveMetadata
              ? descriptiveMetadata.description
              : "No description provided"}
          </p>
        </div>
        <div className="box is-shadowless">
          <h3 className="small-title">Date Created</h3>
          <p>{formatDate(work.insertedAt)}</p>
        </div>
        <div className="box is-shadowless">
          <h3 className="small-title">Creators</h3>
          <p className="notification is-warning">
            Need this exposed in GraphQL
          </p>
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
        <div className="box is-shadowless">
          <h3 className="small-title">Contributors</h3>
          <p className="notification is-warning">
            Need this exposed in GraphQL
          </p>
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
    </div>
  );
};

WorkTabsAbout.propTypes = {
  work: PropTypes.object
};

export default WorkTabsAbout;
