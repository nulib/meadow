import React from "react";
import { Link } from "react-router-dom";
import PropTypes from "prop-types";
import UIWorkImage from "./WorkImage";
import { getImageUrl } from "@js/services/helpers";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const previewContainer = css`
  max-height: 440px;
  overflow-y: auto;
`;

const MAX_ITEMS_SHOWN = 25;

export default function UIPreviewItems({ items = [] }) {
  return (
    <div className="is-centered" css={previewContainer}>
      <ul className="columns is-multiline" data-testid="list-preview-items">
        {items.slice(0, MAX_ITEMS_SHOWN).map(({ id, representativeImage }) => (
          <li key={id} className="column is-one-fifth hvr-shrink">
            <Link to={`/work/${id}`} target="_blank">
              <UIWorkImage
                imageUrl={getImageUrl(representativeImage)}
                size={256}
              />
            </Link>
          </li>
        ))}
      </ul>
      {items.length > MAX_ITEMS_SHOWN && (
        <p className="has-text-centered">
          Preview limited to {MAX_ITEMS_SHOWN} items...
        </p>
      )}
    </div>
  );
}

UIPreviewItems.propTypes = {
  items: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string,
      representativeFileSet: PropTypes.object,
    })
  ),
};
