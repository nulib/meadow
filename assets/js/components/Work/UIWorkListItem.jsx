import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { setVisibilityClass, formatDate } from "../../services/helpers";

const WorkListItem = ({ work }) => {
  const fileSetsToDisplay = 5;
  return (
    <>
      <article className="media " data-testid="ui-worklist-item">
        <figure className="media-left">
          <p className="image is-128x128">
            <Link to={`/work/${work.id}`}>
              <img
                src={`${
                  work.representativeImage
                    ? work.representativeImage + "/full/1280,960/0/default.jpg"
                    : "/images/1280x960.png"
                }`}
                data-testid="image-work"
                alt={work.title}
              />
            </Link>
          </p>
        </figure>
        <div className="media-content">
          <h3 className="title is-size-4">
            {work.descriptiveMetadata.title
              ? work.descriptiveMetadata.title
              : "Untitled"}
          </h3>
          <div className="content ">
            <p>
              <span className="tag">{work.workType}</span>
              <span
                data-testid="tag-visibility"
                className={`tag ${setVisibilityClass(work.visibility)}`}
              >
                {work.visibility.toUpperCase()}
              </span>
              {work.published && (
                <span data-testid="dd-published" className="tag is-success">
                  PUBLISHED
                </span>
              )}
            </p>
            <table className="table">
              <thead>
                <tr>
                  <th>Accession Number</th>
                  <th>Filesets</th>
                  <th>Last Updated</th>
                  <th>IIIF Manifest</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td data-testid="dd-accession-number">
                    {work.accessionNumber}
                  </td>
                  <td>
                    <span
                      className="tag is-light"
                      data-testid="dd-filesets-length"
                    >
                      {work.fileSets.length}
                    </span>
                  </td>
                  <td data-testid="dd-updated-date">
                    {formatDate(work.updatedAt)}
                  </td>
                  <td>
                    <a href={work.manifestUrl} target="_blank">
                      <u>JSON File</u>
                    </a>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <div className="media-right "></div>
      </article>
    </>
  );
};

WorkListItem.propTypes = {
  work: PropTypes.object,
};

export default WorkListItem;
