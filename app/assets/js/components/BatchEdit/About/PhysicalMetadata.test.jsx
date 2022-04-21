import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAboutPhysicalMetadata from "./PhysicalMetadata";
import { PHYSICAL_METADATA } from "../../../services/metadata";

describe("BatchEditAboutPhysicalMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAboutPhysicalMetadata);
    return renderWithRouterApollo(<Wrapped />);
  });

  it("renders the component", () => {
    expect(screen.getByTestId("physical-metadata"));
  });

  it("renders expected physical metadata fields", async () => {
    for (let item of PHYSICAL_METADATA) {
      expect(screen.getByTestId(item.name));
    }
  });
});
