import React from "react";
import { renderWithRouterApollo } from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutPhysicalMetadata from "./PhysicalMetadata";
import { waitFor } from "@testing-library/react";
import { PHYSICAL_METADATA } from "../../../../services/metadata";

describe("Work About tab Idenfiers Metadata component", () => {
  function setupTests() {
    return renderWithRouterApollo(
      <WorkTabsAboutPhysicalMetadata
        descriptiveMetadata={mockWork.descriptiveMetadata}
      />
    );
  }

  it("renders physical metadata component", async () => {
    let { queryByTestId } = setupTests();
    await waitFor(() => {
      expect(queryByTestId("physical-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected physical metadata fields", async () => {
    let { getByTestId } = setupTests(true);

    await waitFor(() => {
      for (let item of PHYSICAL_METADATA) {
        expect(getByTestId(item.name)).toBeInTheDocument();
      }
    });
  });
});
