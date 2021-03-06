import React, { useContext } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import {
  setVisibilityClass,
  formatDate,
  getImageUrl,
} from "@js/services/helpers";
import UIWorkImage from "../UI/WorkImage";
import { Tag } from "@nulib/admin-react-components";
import UIVisibilityTag from "@js/components/UI/VisibilityTag";

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
            <Link to={`/work/${id}`} title="View work">
              <UIWorkImage
                imageUrl={getImageUrl(representativeImage)}
                size={500}
              />
            </Link>
          </div>
        </figure>
        <div className="media-content">
          <p className="small-title block">
            <Link to={`/work/${id}`}>{title ? title : "Untitled"}</Link>
          </p>
          <div className="tags">
            <Tag isInfo>{workType.label}</Tag>
            {published ? (
              <Tag isSuccess data-testid="result-item-published">
                Published
              </Tag>
            ) : (
              <Tag>Unpublished</Tag>
            )}
            {visibility.id && (
              <UIVisibilityTag
                data-testid="tag-visibility"
                visibility={visibility}
              />
            )}
          </div>

          <div className="content ">
            <span
              title="Accession number"
              data-testid="result-item-accession-number"
            >
              {accessionNumber}
            </span>
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
