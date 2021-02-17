import React from "react";
import { render, screen } from "@testing-library/react";
import IngestSheetDetails from "@js/components/IngestSheet/Details";

describe("IngestSheetDetails component", () => {
  beforeEach(() => {
    render(<IngestSheetDetails />);
  });

  it("renders", () => {
    expect(screen.getByTestId("ingest-sheet-details"));
  });
});
