import React, { useContext } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { setVisibilityClass, formatDate } from "../../services/helpers";
import { IIIFProvider, IIIFContext } from "../../components/IIIF/IIIFProvider";

const WorkListItem = ({
  id,
  representativeImage,
  title,
  descriptiveMetadata,
  workType,
  visibility,
  published,
  accessionNumber,
  fileSets,
  manifestUrl,
  updatedAt,
}) => {
  const iiifServerUrl = useContext(IIIFContext);
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
                    ? iiifServerUrl +
                      representativeImage.id +
                      "/square/500,500/0/default.jpg"
                    : representativeImage + "/full/1280,960/0/default.jpg"
                }`}
                data-testid="image-work"
                alt={title}
              />
            </Link>
          </p>
        </figure>
        <div className="media-content">
          <h3 className="title is-size-4">
            {descriptiveMetadata.title ? descriptiveMetadata.title : "Untitled"}
          </h3>
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
                  <td data-testid="dd-accession-number">{accessionNumber}</td>
                  <td>
                    <span
                      className="tag is-light"
                      data-testid="dd-filesets-length"
                    >
                      {fileSets.length}
                    </span>
                  </td>
                  <td data-testid="dd-updated-date">{formatDate(updatedAt)}</td>
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
