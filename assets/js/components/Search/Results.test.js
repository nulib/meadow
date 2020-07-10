import React from "react";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import SearchResults from "./Results";
import { iiifServerUrlMock } from "../IIIF/iiif.gql.mock";

// Mock GraphQL queries
const mocks = [iiifServerUrlMock];

describe("SearchResults component", () => {
  it("renders", () => {
    expect(renderWithRouterApollo(<SearchResults />));
  });

  // Note currently doesn't seem that ReactiveSearch provides any kind of mocking
  // Provider mechanism.  So it's near impossible to test what ReactiveSearch renders...
});
