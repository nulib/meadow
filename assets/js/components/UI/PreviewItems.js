import React from "react";
import { Link } from "react-router-dom";
import PropTypes from "prop-types";
import UIWorkImage from "./WorkImage";
import { getImageUrl } from "@js/services/helpers";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";

export default function UIPreviewItems({ items = [] }) {
  return (
    <div className="is-centered">
      <ul className="columns is-multiline" data-testid="list-preview-items">
        {items.map(({ id, representativeImage }) => (
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
