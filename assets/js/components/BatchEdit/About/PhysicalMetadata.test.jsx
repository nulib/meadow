import React from "react";
import { waitFor } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookFormControl,
} from "../../../services/testing-helpers";
import BatchEditAboutPhysicalMetadata from "./PhysicalMetadata";
import { PHYSICAL_METADATA } from "../../../services/metadata";

describe("BatchEditAboutPhysicalMetadata component", () => {
  function setupTest() {
    const Wrapped = withReactHookFormControl(BatchEditAboutPhysicalMetadata);
    return renderWithRouterApollo(<Wrapped />);
  }
  it("renders the component", async () => {
    let { queryByTestId } = setupTest();
    await waitFor(() => {
      expect(queryByTestId("physical-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected physical metadata fields", async () => {
    let { getByTestId } = setupTest();

    await waitFor(() => {
      for (let item of PHYSICAL_METADATA) {
        expect(getByTestId(item.name)).toBeInTheDocument();
      }
    });
  });
});
