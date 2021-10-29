import React from "react";
import { screen, render } from "@testing-library/react";
import UIWorkImage from "./WorkImage";
import { getImageUrl } from "@js/services/helpers";

const imageUrl = getImageUrl("www.northwestern.edu");
describe("UIWorkImage component", () => {
  it("renders UIWorkImage placeholder", () => {
    render(<UIWorkImage imageUrl="" workType="Image" />);
    const figureEl = screen.getByTestId("work-image");
    expect(figureEl);
    expect(figureEl.firstChild.firstChild.nodeName).toBe("svg");
  });

  it("renders correct Image source", () => {
    render(<UIWorkImage imageUrl={imageUrl} size={500} workType="Image" />);
    const imageEl = screen.getByTestId("image-source");
    expect(imageEl.getAttribute("src")).toContain(
      `www.northwestern.edu/square/500,500/0/default.jpg`
    );
    const figureEl = screen.getByTestId("work-image");
    expect(figureEl).toHaveClass(`is-square`);
  });
});
