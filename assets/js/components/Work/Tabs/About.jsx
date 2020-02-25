import React, { useContext, useState } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { formatDate } from "../../../services/helpers";
import { WorkFormContext } from "../FormProvider";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const WorkTabsAbout = ({ work }) => {
  const isEditing = useContext(WorkFormContext);
  const { descriptiveMetadata } = work;
  const [description, setDescription] = useState(
    descriptiveMetadata.description
  );
  const [insertedAt, setInsertedAt] = useState(work.insertedAt);
  const [showCoreMetadata, setShowCoreMetadata] = useState(true);
  const [showDescriptiveMetadata, setShowDescriptiveMetadata] = useState(true);

  return (
    <div className="columns is-centered" data-testid="tab-about-content">
      <div className="column is-three-quarters">
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
          <div className="box">
            <div className="field">
              <label className="label">Description</label>
              <div className="control">
                {isEditing ? (
                  <textarea
                    name="description"
                    className="textarea"
                    placeholder="e.g. Hello world"
                    value={descriptiveMetadata.description}
                    onChange={e => setDescription(e.target.value)}
                  />
                ) : (
                  <p className="has-text-grey">
                    {descriptiveMetadata.description ||
                      "No description provided"}
                  </p>
                )}
              </div>
            </div>
            <div className="field">
              <label className="label">
                Date Created (Should this be editable?)
              </label>
              <div className="control">
                {isEditing ? (
                  <input
                    name="insertedAt"
                    className="input"
                    type="date"
                    value={insertedAt}
                    onChange={e => setInsertedAt(e.target.value)}
                  />
                ) : (
                  <p>{formatDate(work.insertedAt)}</p>
                )}
              </div>
            </div>
          </div>
        )}

        <h2 className="title is-size-5">
          Descriptive Metadata{" "}
          <a
            onClick={() => setShowDescriptiveMetadata(!showDescriptiveMetadata)}
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
          <div className="box">
            <div className="field">
              <label className="label">Creators</label>
              <div className="control">
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
            </div>

            <div className="field">
              <label className="label">Contributors</label>
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
        )}
      </div>
    </div>
  );
};

WorkTabsAbout.propTypes = {
  work: PropTypes.object
};

export default WorkTabsAbout;
