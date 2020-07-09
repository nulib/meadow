import React from "react";
import { Link } from "react-router-dom";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";

const inlineList = css`
  white-space: nowrap;
  overflow: auto;
  scrollbar-color: #4e2a84 #ccc;
  scrollbar-width: thin;
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
  margin: 0 1rem 1rem 0;
`;

export default function BatchEditPreviewItems(props) {
  const { items } = props;
  return (
    <div>
      <h2 className="title is-size-4">Preview of items go here</h2>
      <div className="is-centered ">
        <ul css={inlineList} data-testid="list-preview-items">
          {items.map((item) => (
            <li key={item.id} css={inlineListElem}>
              <Link to={`/work/${item.id}`} target="_blank">
                <figure>
                  <img
                    data-testid="image-preview"
                    src={
                      item.representativeImage
                        ? `${item.representativeImage}/square/256,256/0/default.jpg`
                        : "https://bulma.io/images/placeholders/256x256.png"
                    }
                  />
                  <h2 className="subtitle" style={{ textAlign: "center" }}>
                    {item.descriptiveMetadata.title}
                  </h2>
                </figure>
              </Link>
            </li>
          ))}
          <li key={1} css={inlineListElem}>
            <h3 className="subtitle is-size-5">
              ... This is a preview of works selected for batch edit.
              <br /> Displayed here are a few items from your selection.
            </h3>
          </li>
        </ul>
      </div>
    </div>
  );
}
