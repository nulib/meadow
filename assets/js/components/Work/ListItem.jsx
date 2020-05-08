import React, { useContext } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { setVisibilityClass, formatDate } from "../../services/helpers";

const WorkListItem = ({
  id,
  representativeImage,
  title,
  workType,
  visibility,
  published,
  accessionNumber,
  fileSets,
  manifestUrl,
  updatedAt,
}) => {
  return (
    <>
      <article className="media" data-testid="ui-worklist-item">
        <figure className="media-left">
          <p className="image is-128x128">
            <Link to={`/work/${id}`}>
              <img
                src={`${
                  representativeImage.id
                    ? representativeImage.url + "/square/500,500/0/default.jpg"
                    : representativeImage + "/full/1280,960/0/default.jpg"
                }`}
                data-testid="image-work"
                alt={title}
              />
            </Link>
          </p>
        </figure>
        <div className="media-content">
          <div className="level">
            <div className="level-left">
              <div className="level-item">
                <h3 className="title is-size-4">
                  <Link to={`/work/${id}`}>{title || "Untitled"}</Link>{" "}
                </h3>
              </div>
              <div className="level-item">
                <span className="tag">{workType.label.toUpperCase()}</span>
              </div>
              {visibility && (
                <div className="level-item">
                  <span
                    data-testid="tag-visibility"
                    className={`tag ${setVisibilityClass(visibility.id)}`}
                  >
                    {visibility.label.toUpperCase()}
                  </span>
                </div>
              )}

              {published && (
                <div className="level-item">
                  <span
                    data-testid="result-item-published"
                    className="tag is-success"
                  >
                    PUBLISHED
                  </span>
                </div>
              )}

              <div className="level-item">
                <a
                  href={manifestUrl}
                  target="_blank"
                  className="card-footer-item"
                >
                  <figure className="image is-32x32">
                    <img
                      src="/images/IIIF-logo.png"
                      alt="IIIF logo"
                      title="View IIIF manifest"
                    />
                  </figure>
                </a>
              </div>
            </div>
          </div>

          <div className="content ">
            <table className="table">
              <thead>
                <tr>
                  <th>Accession Number</th>
                  <th># Filesets</th>
                  <th>Last Updated</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td data-testid="result-item-accession-number">
                    {accessionNumber}
                  </td>
                  <td data-testid="result-item-filesets-length">{fileSets}</td>
                  <td data-testid="result-item-updated-date">
                    {formatDate(updatedAt)}
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
