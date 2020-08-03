import React from "react";
import { waitFor } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookFormControl,
} from "../../../services/testing-helpers";
import BatchEditAboutUncontrolledMetadata from "./UncontrolledMetadata";
import { UNCONTROLLED_METADATA } from "../../../services/metadata";

describe("BatchEditAboutUncontrolledMetadata component", () => {
  function setupTest() {
    const Wrapped = withReactHookFormControl(
      BatchEditAboutUncontrolledMetadata
    );
    return renderWithRouterApollo(<Wrapped />);
  }
  it("renders the component", async () => {
    let { queryByTestId } = setupTest();
    await waitFor(() => {
      expect(queryByTestId("uncontrolled-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected uncontrolled metadata fields", async () => {
    let { getByTestId } = setupTest();

    await waitFor(() => {
      for (let item of UNCONTROLLED_METADATA) {
        expect(getByTestId(item.name)).toBeInTheDocument();
      }
    });
  });
});
