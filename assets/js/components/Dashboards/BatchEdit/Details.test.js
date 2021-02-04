import React from "react";
import { screen, render } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import DashboardsBatchEditDetails from "./Details";
import { getBatchMock } from "@js/components/Dashboards/dashboards.gql.mock";
import { isReference } from "@apollo/client";

describe("DashboardsBatchEditDetails", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsBatchEditDetails id="ABC123" />, {
      mocks: [getBatchMock],
    });
  });

  it("renders", async () => {
    expect(await screen.findByTestId("batch-details"));
  });

  it("renders display fields", async () => {
    const values = ["My Batch Job", "COMPLETE", "UPDATE", "aja0137", "43"];
    expect(await screen.findByTestId("batch-details"));
    for (let x of values) {
      expect(screen.getByText(x));
    }
  });

  it("displays View Works button", async () => {
    expect(await screen.findByTestId("button-to-search"));
  });
});
