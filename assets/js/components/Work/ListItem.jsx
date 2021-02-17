import React, { useContext } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import {
  setVisibilityClass,
  formatDate,
  getImageUrl,
} from "@js/services/helpers";
import UIWorkImage from "../UI/WorkImage";

const WorkListItem = ({
  id,
  representativeImage,
  title,
  workType = { id: "", label: "", scheme: "" },
  visibility = { id: "", label: "", scheme: "" },
  published,
  accessionNumber,
  fileSets,
  updatedAt,
}) => {
  return (
    <>
      <article className="media" data-testid="ui-worklist-item">
        <figure className="media-left">
          <div className="image is-128x128">
            <Link to={`/work/${id}`}>
              <UIWorkImage
                imageUrl={getImageUrl(representativeImage)}
                size={500}
              />
            </Link>
          </div>
        </figure>
        <div className="media-content">
          <h3 className="title is-size-5">
            <Link
              to={`/work/${id}`}
              dangerouslySetInnerHTML={{
                __html: title ? title : "Untitled",
              }}
            ></Link>
          </h3>
          {workType.label && (
            <span className="tag mr-1">{workType.label.toUpperCase()}</span>
          )}
          {visibility.id && (
            <span
              data-testid="tag-visibility"
              className={`tag mr-1 ${setVisibilityClass(visibility.id)}`}
            >
              {visibility.label.toUpperCase()}
            </span>
          )}
          {published && (
            <span
              data-testid="result-item-published"
              className="tag is-success mr-1"
            >
              PUBLISHED
            </span>
          )}

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
                  <td
                    data-testid="result-item-accession-number"
                    style={{ wordBreak: "break-all" }}
                    dangerouslySetInnerHTML={{ __html: accessionNumber }}
                  ></td>
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
