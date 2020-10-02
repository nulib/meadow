import React from "react";
import WorkTabsStructureFilesets from "./Filesets";
import { render, screen } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";

describe("WorkTabsStructureFilesets components", () => {
  it("renders the component", () => {
    render(<WorkTabsStructureFilesets filesets={mockFileSets} />);
    expect(screen.getByTestId("fileset-list"));
  });

  it("renders a list of filesets with an image, label and description", () => {
    render(<WorkTabsStructureFilesets filesets={mockFileSets} />);

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
    render(<WorkTabsStructureFilesets filesets={mockFileSets} />);
    expect(screen.getAllByTestId("work-image-selector")).toHaveLength(3);
  });
});
