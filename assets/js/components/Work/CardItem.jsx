import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { getImageUrl } from "@js/services/helpers";
import UIWorkImage from "@js/components/UI/WorkImage";
import { Tag } from "@nulib/admin-react-components";
import UIVisibilityTag from "@js/components/UI/VisibilityTag";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const breakWord = css`
  word-break: break-all;
`;

const WorkCardItem = ({
  id,
  representativeImage,
  title,
  workType = { id: "", label: "", scheme: "" },
  visibility = { id: "", label: "", scheme: "" },
  published,
  accessionNumber,
  collectionName,
}) => {
  return (
    <div className="card" data-testid="ui-workcard">
      <div className="card-image">
        <figure className="image is-3by3">
          <Link to={`/work/${id}`}>
            <UIWorkImage
              imageUrl={getImageUrl(representativeImage)}
              size={500}
              workTypeId={workType.id}
            />
          </Link>
        </figure>
      </div>
      <div className="card-content content">
        <div className="tags">
          {workType.id && (
            <Tag isInfo data-testid="tag-work-type">
              {workType.label}
            </Tag>
          )}
          {published ? (
            <Tag isSuccess data-testid="result-item-published">
              Published
            </Tag>
          ) : (
            <Tag>Not Published</Tag>
          )}
          {visibility.id && (
            <UIVisibilityTag
              visibility={visibility}
              data-testid="tag-visibility"
            />
          )}
        </div>
        <p data-testid={`work-title-${id}`}>{title}</p>
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
