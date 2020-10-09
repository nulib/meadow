import React from "react";
import UIPreviewItems from "./PreviewItems";
import { renderWithRouter } from "../../services/testing-helpers";
import { batchEditPreviewItems } from "../../mock-data/batch-edit-preview-items";

describe("Batch-edit preview items component", () => {
  function setUpTests() {
    return renderWithRouter(<UIPreviewItems items={batchEditPreviewItems} />);
  }
  it("renders the list", () => {
    const { getByTestId, debug } = setUpTests();
    expect(getByTestId("list-preview-items")).toBeInTheDocument();
  });

  it("renders all items passed to list", () => {
    const { getByTestId, debug } = setUpTests();
    const el = getByTestId("list-preview-items");
    expect(el).toBeInTheDocument();
    //+1 for the last hint element
    expect(el.querySelectorAll("li")).toHaveLength(
      batchEditPreviewItems.length
    );
  });

  it("renders correct data for list elements", () => {
    const { getByTestId } = setUpTests();
    const el = getByTestId("list-preview-items");

    const anchorEls = el.querySelectorAll("a");
    const imageEls = el.querySelectorAll("img");

    // Renders correct anchor tags
    expect(anchorEls[2].getAttribute("href")).toEqual(
      "/work/" + batchEditPreviewItems[2].id
    );
    expect(anchorEls[9].getAttribute("href")).toEqual(
      "/work/" + batchEditPreviewItems[9].id
    );

    //Renders correct image
    expect(imageEls[0].getAttribute("src")).toContain(
      `${batchEditPreviewItems[0].representativeImage.url}/square/128,128/0/default.jpg`
    );

    // Renders default image
    expect(imageEls[2].getAttribute("src")).toContain(
      `https://bulma.io/images/placeholders/128x128.png`
    );
  });
});
