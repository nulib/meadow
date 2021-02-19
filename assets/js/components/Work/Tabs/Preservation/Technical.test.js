import React from "react";
import { screen, render } from "@testing-library/react";
import WorkTabsPreservationTechnical from "@js/components/Work/Tabs/Preservation/Technical";
import { mockWork } from "@js/components/Work/work.gql.mock";

describe("WorkTabsPreservationTechnical component", () => {
  it("renders", () => {
    render(<WorkTabsPreservationTechnical />);
    expect(screen.getByTestId("technical-metadata"));
  });

  it("displays technical metadata if it exists", () => {
    render(<WorkTabsPreservationTechnical fileSet={mockWork.fileSets[0]} />);
    expect(screen.getByText("Artist").nextElementSibling).toHaveTextContent(
      "Artist Name"
    );
    expect(
      screen.getByText("Compression").nextElementSibling
    ).toHaveTextContent("1");
    expect(
      screen.getByText("ImageHeight").nextElementSibling
    ).toHaveTextContent("1024");
  });

  it("displays handles display of technical metadata whose value is of type object", () => {
    render(<WorkTabsPreservationTechnical fileSet={mockWork.fileSets[0]} />);
    expect(
      screen.getByText("BitsPerSample").nextElementSibling
    ).toHaveTextContent("0, 1, 2");
  });

  it("displays a message saying no data exists", () => {
    render(<WorkTabsPreservationTechnical />);
    expect(screen.getByTestId("no-data-notification"));
  });
});
