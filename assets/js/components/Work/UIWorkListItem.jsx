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
          <p
            className="image is-square"
            style={{ width: "250px", height: "250px" }}
          >
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
          <h3 className="title is-size-4">{title ? title : "Untitled"}</h3>
          <div className="content ">
            <p>
              <span className="tag">{workType.label.toUpperCase()}</span>
              {visibility && (
                <span
                  data-testid="tag-visibility"
                  className={`tag ${setVisibilityClass(visibility.id)}`}
                >
                  {visibility.label.toUpperCase()}
                </span>
              )}
              {published && (
                <span
                  data-testid="result-item-published"
                  className="tag is-success"
                >
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
                  <td data-testid="result-item-accession-number">
                    {accessionNumber}
                  </td>
                  <td>
                    <span
                      className="tag is-light"
                      data-testid="result-item-filesets-length"
                    >
                      {fileSets}
                    </span>
                  </td>
                  <td data-testid="result-item-updated-date">
                    {formatDate(updatedAt)}
                  </td>
                  <td>
                    <a href={manifestUrl} target="_blank">
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
