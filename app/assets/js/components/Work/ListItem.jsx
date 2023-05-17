import React, { useContext } from "react";
/** @jsx jsx */
import { css, jsx } from "@emotion/react";

import { Link } from "react-router-dom";
import PropTypes from "prop-types";
import { Tag } from "@nulib/design-system";
import UIVisibilityTag from "@js/components/UI/VisibilityTag";
import UIWorkImage from "../UI/WorkImage";
import { getIIIFImageUrl } from "@js/services/helpers";

const breakWord = css`
  word-break: break-all;
`;

const WorkListItem = ({
  accessionNumber,
  id,
  published,
  representativeImage,
  title,
  visibility,
  workTypeId,
}) => {
  return (
    <>
      <article className="media" data-testid="ui-worklist-item">
        <figure className="media-left">
          <div className="image is-128x128">
            <Link to={`/work/${id}`} title="View work">
              <UIWorkImage
                imageUrl={getIIIFImageUrl(representativeImage)}
                size={500}
                workTypeId={workTypeId}
              />
            </Link>
          </div>
        </figure>
        <div className="media-content">
          <p className="small-title block">
            <Link to={`/work/${id}`} css={breakWord}>
              {title ? title : ""}
            </Link>
          </p>
          <div className="tags">
            <Tag isInfo>{workTypeId}</Tag>
            {published ? (
              <Tag isSuccess data-testid="result-item-published">
                Published
              </Tag>
            ) : (
              <Tag>Unpublished</Tag>
            )}
            {visibility && (
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
