import React from "react";
import Work from "./Work";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { mockWork } from "./work.gql.mock";
import { iiifServerUrlMock } from "../IIIF/iiif.gql.mock";

const mocks = [iiifServerUrlMock];

describe("Work component", () => {
  function setupTests() {
    return renderWithRouterApollo(<Work work={mockWork} />, { mocks });
  }

  it("renders without crashing", () => {
    expect(setupTests()).toBeTruthy();
  });

  it("renders the viewer and tabs", () => {
    const { getByTestId } = setupTests();

    expect(getByTestId("viewer")).toBeInTheDocument();
    expect(getByTestId("tabs-wrapper")).toBeInTheDocument();
  });
});
