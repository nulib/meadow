import React from "react";
import BatchEditPreviewItems from "./PreviewItems";
import { renderWithRouter } from "../../services/testing-helpers";
import { mockBatchEditData } from "../../mock-data/batchEditData";

describe("Batch-edit preview items component", () => {
  function setUpTests() {
    return renderWithRouter(
      <BatchEditPreviewItems items={mockBatchEditData} />
    );
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
      mockBatchEditData.length + 1
    );
  });
  it("renders correct data for list elements", () => {
    const { getByTestId } = setUpTests();
    const el = getByTestId("list-preview-items");

    const anchorEls = el.querySelectorAll("a");
    const imageEls = el.querySelectorAll("img");
    const headerEls = el.querySelectorAll("h2");

    // Renders a header with correct title
    expect(headerEls[2].innerHTML).toEqual(
      mockBatchEditData[2].descriptiveMetadata.title
    );
    expect(headerEls[7].innerHTML).toEqual(
      mockBatchEditData[7].descriptiveMetadata.title
    );

    // Renders correct anchor tags
    expect(anchorEls[2].getAttribute("href")).toEqual(
      "/work/" + mockBatchEditData[2].id
    );
    expect(anchorEls[9].getAttribute("href")).toEqual(
      "/work/" + mockBatchEditData[9].id
    );

    //Renders default image
    expect(imageEls[0].getAttribute("src")).toEqual(
      mockBatchEditData[0].representativeImage
        ? mockBatchEditData[0].representativeImage +
            "/square/256,256/0/default.jpg"
        : "https://bulma.io/images/placeholders/256x256.png"
    );
  });
});
