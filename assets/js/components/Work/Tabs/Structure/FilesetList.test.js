import React from "react";
import WorkTabsStructureFilesetList from "./FilesetList";
import { render, screen } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import { withReactBeautifulDND } from "@js/services/testing-helpers";

describe("WorkTabsStructureFilesets components", () => {
  it("renders a draggable list component if re-ordering the list", () => {
    render(
      withReactBeautifulDND(WorkTabsStructureFilesetList, {
        fileSets: mockFileSets,
        isReordering: true,
      })
    );
    expect(screen.getByTestId("fileset-draggable-list"));
  });

  it("renders a non-draggable list if not-reordering", () => {
    render(
      withReactBeautifulDND(WorkTabsStructureFilesetList, {
        fileSets: mockFileSets,
      })
    );
    expect(screen.getByTestId("fileset-list"));
  });

  it("renders the correct number of list elements", () => {
    render(
      withReactBeautifulDND(WorkTabsStructureFilesetList, {
        fileSets: mockFileSets,
      })
    );
    expect(screen.getByTestId("fileset-list").children).toHaveLength(3);
  });
});
