import React from "react";
import DashboardsCsvImport from "./Import";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";

describe("DashboardsCsvImport component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsCsvImport />);
  });

  it("renders", () => {
    expect(screen.getByTestId("csv-job-import-wrapper"));
  });

  it("renders the import button", () => {
    expect(screen.getByTestId("import-csv-button"));
  });

  it("renders the import modal component", () => {
    expect(screen.getByTestId("import-csv-modal"));
  });
});
