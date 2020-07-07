import React from "react";
import { Link } from "react-router-dom";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";

const inlineList = css`
  white-space: nowrap;
  overflow: auto;
  ::-webkit-scrollbar {
    height: 0.5rem;
    background-color: #ccc;
  }
  ::-webkit-scrollbar-track {
    border-radius: 1rem;
  }

  ::-webkit-scrollbar-thumb {
    background: #4e2a84;
    border-radius: 1rem;
  }
`;

const inlineListElem = css`
  display: inline-block;
  margin-left: 1rem;
`;

const figCaption = css`
  text-align: center;
  margin-bottom: 1rem;
`;

export default function BatchEditPreviewItems(props) {
  const { selectedItems } = props;
  return (
    <div>
      <h2 className="title is-size-4">Preview of items go here</h2>
      <div className="is-centered ">
        <ul css={inlineList} data-testid="list-preview-items">
          {selectedItems.map((item) => (
            <li key={item.id} css={inlineListElem}>
              <Link to={`/work/${item.id}`} target="_blank">
                <figure>
                  <img
                    data-testid="image-preview"
                    src={`${item.representativeImage}/square/200,200/0/default.jpg`}
                  />
                  <figcaption css={figCaption}>
                    <h4 className="subtitle is-size-6">
                      {item.descriptiveMetadata.title}
                    </h4>
                  </figcaption>
                </figure>
              </Link>
            </li>
          ))}
          <li key={1} css={inlineListElem}>
            <h3 className="subtitle is-size-5">
              ... This is a preview of works selected for batch edit.
              <br /> Shown are only 50 items.
            </h3>
          </li>
        </ul>
      </div>
    </div>
  );
}
