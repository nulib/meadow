import React from "react";
import WorkFilesetDraggable from "./Draggable";
import { render, screen } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import { withReactBeautifulDND } from "@js/services/testing-helpers";

describe("WorkFilesetDraggable components", () => {
  beforeEach(() => {
    render(
      withReactBeautifulDND(WorkFilesetDraggable, {
        fileSet: mockFileSets[0],
        index: 0,
      })
    );
  });

  it("renders a draggable list component", () => {
    expect(screen.getByTestId("fileset-draggable-item"));
  });

  it("renders image, label and description", () => {
    expect(screen.getByTestId("fileset-image"));
    expect(screen.getByTestId("fileset-label")).toHaveTextContent(
      mockFileSets[0].coreMetadata.label
    );
    expect(screen.getByTestId("fileset-description")).toHaveTextContent(
      mockFileSets[0].coreMetadata.description
    );
  });
});
