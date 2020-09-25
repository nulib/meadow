import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  setupCachedCodeListsLocalStorage,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAboutControlledMetadata from "./ControlledMetadata";
import { CONTROLLED_METADATA } from "../../../services/metadata";
import { BatchProvider } from "../../../context/batch-edit-context";

describe("BatchEditAboutCoreMetadata component", () => {
  beforeEach(() => {
    setupCachedCodeListsLocalStorage();
    const Wrapped = withReactHookForm(BatchEditAboutControlledMetadata);

    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <Wrapped />
      </BatchProvider>,
      {
        mocks: [],
      }
    );
  });
  it("renders controlled metadata component", async () => {
    expect(await screen.findByTestId("controlled-metadata"));
  });

  it("renders expected controlled metadata fields", async () => {
    for (let item of CONTROLLED_METADATA) {
      expect(await screen.findByTestId(item.name));
    }
  });
});
