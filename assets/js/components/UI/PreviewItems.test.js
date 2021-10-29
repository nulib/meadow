import React from "react";
import UIPreviewItems from "./PreviewItems";
import { renderWithRouter } from "../../services/testing-helpers";
import { batchEditPreviewItems } from "../../mock-data/batch-edit-preview-items";
import { screen } from "@testing-library/react";

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
    expect(el.querySelectorAll("li")).toHaveLength(10);
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

    // Renders correct image
    expect(imageEls[0].getAttribute("src")).toContain(
      `${batchEditPreviewItems[0].representativeImage.url}/square/256,256/0/default.jpg`
    );
    expect(anchorEls[0].querySelector("svg")).toBeNull();

    // Renders default image
    expect(anchorEls[2].querySelector("svg")).not.toBeNull();
  });
});
