/** @jsx jsx */
import { css, jsx } from "@emotion/react";

import { Link } from "react-router-dom";
import PropTypes from "prop-types";
import React from "react";
import { Tag } from "@nulib/design-system";
import UIVisibilityTag from "@js/components/UI/VisibilityTag";
import UIWorkImage from "@js/components/UI/WorkImage";
import { getIIIFImageUrl } from "@js/services/helpers";

const breakWord = css`
  word-break: break-all;
`;

const WorkCardItem = ({
  accessionNumber,
  collectionName,
  id,
  published,
  representativeImage,
  title,
  visibility,
  workTypeId,
}) => {
  return (
    <div className="card" data-testid="ui-workcard">
      <div className="card-image">
        <figure className="image is-3by3">
          <Link to={`/work/${id}`}>
            <UIWorkImage
              imageUrl={getIIIFImageUrl(representativeImage)}
              size={500}
              workTypeId={workTypeId}
            />
          </Link>
        </figure>
      </div>
      <div className="card-content content">
        <div className="tags">
          {workTypeId && (
            <Tag isInfo data-testid="tag-work-type">
              {workTypeId}
            </Tag>
          )}
          {published ? (
            <Tag isSuccess data-testid="result-item-published">
              Published
            </Tag>
          ) : (
            <Tag>Not Published</Tag>
          )}
          {visibility && (
            <UIVisibilityTag
              visibility={visibility}
              data-testid="tag-visibility"
            />
          )}
        </div>
        <p data-testid={`work-title-${id}`} css={breakWord}>
          {title}
        </p>
        <p data-testid="accession-number" css={breakWord}>
          {accessionNumber}
        </p>

        {collectionName && <p className="heading">{collectionName}</p>}
      </div>
    </div>
  );
};

WorkCardItem.propTypes = {
  work: PropTypes.object,
};

export default WorkCardItem;
