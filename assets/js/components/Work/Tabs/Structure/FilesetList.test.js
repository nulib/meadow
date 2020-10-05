import React from "react";
import WorkTabsStructureFilesetList from "./FilesetList";
import { render, screen } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import { withReactBeautifulDND } from "@js/services/testing-helpers";

describe("WorkTabsStructureFilesets components", () => {
  beforeEach(() => {
    render(
      withReactBeautifulDND(WorkTabsStructureFilesetList, {
        filesets: mockFileSets,
      })
    );
  });

  it("renders the component", () => {
    expect(screen.getByTestId("fileset-list"));
  });

  it("renders a list of filesets with an image, label and description", () => {
    const filesetEls = screen.getAllByTestId("fileset-item");
    expect(filesetEls).toHaveLength(3);
    expect(filesetEls[0]).toHaveTextContent(
      "inu-dil-9d35d0ba-a84b-4e0a-99e6-9c6b548a46db.tif"
    );
    expect(filesetEls[0]).toHaveTextContent(
      "inu-dil-9d35d0ba-a84b-4e0a-99e6-9c6b548a46db.jpg"
    );

    expect(screen.getAllByTestId("fileset-image")).toHaveLength(3);
  });

  it("renders a selector element to make fileset a work representative image", () => {
    expect(screen.getAllByTestId("work-image-selector")).toHaveLength(3);
  });
});
