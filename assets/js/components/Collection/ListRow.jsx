import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import CollectionTags from "@js/components/Collection/Tags";
import CollectionImage from "@js/components/Collection/Image";
import IconEdit from "@js/components/Icon/Edit";
import IconDelete from "@js/components/Icon/Delete";
import IconTrashCan from "@js/components/Icon/TrashCan";
import useTruncateText from "@js/hooks/useTruncateText";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const row = css`
  border-bottom: 1px solid #efefef;
  margin-bottom: 2rem;
  padding-bottom: 2rem;
  &:last-of-type {
    border: none;
    margin-bottom: inherit;
    padding-bottom: inherit;
  }
`;

const CollectionListRow = ({ collection, onOpenModal }) => {
  const { id, title = "", description, totalWorks } = collection;
  const { truncate } = useTruncateText();

  return (
    <li data-testid="collection-list-row" css={row}>
      <article className="media">
        <figure className="media-left">
          <p className="image is-128x128">
            <CollectionImage collection={collection} />
          </p>
        </figure>
        <div className="media-content">
          <p className="small-title block">
            <Link to={`/collection/${id}`}>{title}</Link>
          </p>
          <CollectionTags collection={collection} />

          <div>
            <strong># Works:</strong> {totalWorks}
            <br />
            {description && truncate(description, 350)}
          </div>
        </div>
        <div className="media-right">
          <div className="buttons-end">
            <AuthDisplayAuthorized level="MANAGER">
              <p className="control">
                <Link className="button is-light" to={`/collection/form/${id}`}>
                  <IconEdit />
                </Link>
              </p>
            </AuthDisplayAuthorized>
            {totalWorks === 0 && (
              <AuthDisplayAuthorized level="MANAGER">
                <p className="control">
                  <button
                    className="button is-light"
                    onClick={() => onOpenModal({ id, title })}
                  >
                    <IconTrashCan />
                  </button>
                </p>
              </AuthDisplayAuthorized>
            )}
          </div>
        </div>
      </article>
    </li>
  );
};

CollectionListRow.propTypes = {
  collection: PropTypes.object,
};

export default CollectionListRow;
