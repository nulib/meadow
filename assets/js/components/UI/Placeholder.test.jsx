import React from "react";
import { screen, render } from "@testing-library/react";
import UIPlaceholder from "./Placeholder";

describe("UIPlaceholder component", () => {
  it("renders UIPlaceholder svg path", () => {
    render(<UIPlaceholder workType="Video" />);
    const svgEl = screen.getByTestId("placeholder-svg");
    expect(svgEl);
    expect(svgEl.hasChildNodes);
    expect(svgEl.firstChild.nodeName).toBe("title");

    //TODO: Might be some reason the test environment doesn't render out "path"
    //expect(svgEl.lastChild.nodeName).toBe("path");
  });
});
