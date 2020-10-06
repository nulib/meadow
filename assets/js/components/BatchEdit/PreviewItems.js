import React from "react";
import { Link } from "react-router-dom";
import PropTypes from "prop-types";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";

const inlineList = css`
  white-space: nowrap;
  overflow: auto;
  scrollbar-color: #999 #ccc;
  scrollbar-width: thin;
  ::-webkit-scrollbar {
    height: 0.5rem;
    background-color: #ccc;
  }
  ::-webkit-scrollbar-track {
    border-radius: 1rem;
  }
  ::-webkit-scrollbar-thumb {
    background: #999;
    border-radius: 1rem;
  }
`;

const previewItem = css`
  opacity: 1;
  transition: 0.3s;

  &:hover {
    opacity: 0.75;
  }
`;

export default function PreviewItems({ items = [] }) {
  return (
    <div className="is-centered ">
      <ul css={inlineList} data-testid="list-preview-items">
        {items.map(({ id, representativeFileSet, representativeImage }) => (
          <li key={id} className="mr-4 mb-4 is-inline-block" css={previewItem}>
            <Link to={`/work/${id}`} target="_blank" className="hvr-shrink">
              <figure>
                <img
                  data-testid="image-preview"
                  src={
                    representativeImage
                      ? `${representativeImage}/square/128,128/0/default.jpg`
                      : representativeFileSet.url
                      ? `${representativeFileSet.url}/square/128,128/0/default.jpg`
                      : "https://bulma.io/images/placeholders/128x128.png"
                  }
                />
              </figure>
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

PreviewItems.propTypes = {
  items: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string,
      representativeFileSet: PropTypes.object,
    })
  ),
};
