import React from "react";
import { renderWithRouterApollo } from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutIdentifiersMetadata from "./IdentifiersMetadata";
import { waitFor } from "@testing-library/react";
import { IDENTIFIER_METADATA } from "../../../../services/metadata";

describe("Work About tab Idenfiers Metadata component", () => {
  function setupTests() {
    return renderWithRouterApollo(
      <WorkTabsAboutIdentifiersMetadata
        descriptiveMetadata={mockWork.descriptiveMetadata}
      />
    );
  }

  it("renders identifiers metadata component", async () => {
    let { queryByTestId } = setupTests();
    await waitFor(() => {
      expect(queryByTestId("identifiers-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected identifiers metadata fields", async () => {
    let { getByTestId } = setupTests(true);

    await waitFor(() => {
      for (let item of IDENTIFIER_METADATA) {
        expect(getByTestId(item.name)).toBeInTheDocument();
      }
    });
  });
});
