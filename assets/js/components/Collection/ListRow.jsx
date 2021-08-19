import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import CollectionTags from "@js/components/Collection/Tags";
import CollectionImage from "@js/components/Collection/Image";
import { IconEdit, IconDelete, IconTrashCan } from "@js/components/Icon";
import useTruncateText from "@js/hooks/useTruncateText";
import classNames from "classnames";
import { isMobile, isTablet, isDesktop } from "react-device-detect";

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
    <li data-testid="collection-list-row" css={row} className="box">
      <article
        className={classNames(["is-flex", "is-align-items-flex-start"], {
          "is-flex-direction-column": isMobile && !isTablet,
        })}
      >
        <figure
          className={classNames(
            ["image", "is-flex-grow-0", "is-flex-shrink-0", "mr-4", "block"],
            {
              "is-square": isMobile && !isTablet,
              "is-fullwidth": isMobile,
              "is-128x128": isTablet || isDesktop,
            }
          )}
        >
          <CollectionImage collection={collection} />
        </figure>
        <div className="is-flex-grow-1 is-flex-shrink-1">
          <p className="small-title block">
            <Link to={`/collection/${id}`}>{title}</Link>{" "}
            <span className="pl-3 has-text-grey">({totalWorks} works)</span>
          </p>
          <CollectionTags collection={collection} />
          <p className="block">{description && truncate(description, 350)}</p>
        </div>
        <div className="is-flex-grow-0 is-flex-shrink-0">
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
