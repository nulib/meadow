import React from "react";
import {
  renderWithRouterApollo,
  setupCachedCodeListsLocalStorage,
} from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutControlledMetadata from "./ControlledMetadata";
import { waitFor } from "@testing-library/react";

describe("Work About tab Controlled Metadata component", () => {
  function setupTests() {
    setupCachedCodeListsLocalStorage();
    return renderWithRouterApollo(
      <WorkTabsAboutControlledMetadata
        descriptiveMetadata={mockWork.descriptiveMetadata}
      />
    );
  }

  it("renders controlled metadata component", async () => {
    let { queryByTestId } = setupTests();
    await waitFor(() => {
      expect(queryByTestId("controlled-metadata")).toBeInTheDocument();
    });
  });
});
