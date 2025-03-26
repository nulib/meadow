import React from "react";
import WorkFilesetDraggable from "./Draggable";
import {
  getAllByTestId,
  getByTestId,
  render,
  screen,
} from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import { withReactBeautifulDND } from "@js/services/testing-helpers";

describe("WorkFilesetDraggable components", () => {
  beforeEach(() => {
    render(
      withReactBeautifulDND(WorkFilesetDraggable, {
        fileSet: mockFileSets[0],
        index: 0,
        candidateFileSets: [mockFileSets[2]],
        groupedFileSets: [mockFileSets[1]],
      }),
    );
  });

  it("renders a draggable list component", () => {
    const filesets = screen.getAllByTestId("fileset-draggable-item");
    expect(filesets).toHaveLength(2);

    filesets.forEach((fs, index) => {
      expect(fs).toHaveTextContent(mockFileSets[index].coreMetadata.label);
      expect(fs).toHaveTextContent(mockFileSets[index].accessionNumber);

      if (index === 0) {
        expect(fs).toHaveAttribute("data-is-dragging", "false");
        expect(fs).toHaveAttribute("data-is-grouped", "false");
        expect(fs).toHaveAttribute("data-fileset-id", mockFileSets[index].id);

        // attach filesets component is present
        expect(
          fs.querySelector('div[data-testid="fileset-group-add"]'),
        ).toBeInTheDocument();

        // has grouped filesets within it
        const children = fs.querySelectorAll("article");
        expect(children).toHaveLength(1);
      } else {
        expect(fs).toHaveAttribute("data-is-dragging", "false");
        expect(fs).toHaveAttribute("data-is-grouped", "true");
        expect(fs).toHaveAttribute("data-fileset-id", mockFileSets[index].id);

        // detach fileset component is present
        expect(
          fs.querySelector('button[data-testid="fileset-group-remove"]'),
        ).toBeInTheDocument();
      }
    });
  });
});
