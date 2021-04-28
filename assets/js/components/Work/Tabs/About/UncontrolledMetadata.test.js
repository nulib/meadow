import React from "react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { mockWork } from "@js/components/Work/work.gql.mock";
import WorkTabsAboutUncontrolledMetadata from "./UncontrolledMetadata";
import { waitFor } from "@testing-library/react";
import { UNCONTROLLED_METADATA } from "@js/services/metadata";

describe("Work About tab Uncontrolled Metadata component", () => {
  function setupTests() {
    return renderWithRouterApollo(
      <WorkTabsAboutUncontrolledMetadata
        descriptiveMetadata={mockWork.descriptiveMetadata}
      />
    );
  }

  it("renders uncontrolled metadata component", async () => {
    let { queryByTestId } = setupTests();
    await waitFor(() => {
      expect(queryByTestId("uncontrolled-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected uncontrolled metadata fields", async () => {
    let { getByTestId } = setupTests(true);

    await waitFor(() => {
      for (let item of UNCONTROLLED_METADATA) {
        expect(getByTestId(item.name)).toBeInTheDocument();
      }
    });
  });
});
