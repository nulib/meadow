import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAboutUncontrolledMetadata from "./UncontrolledMetadata";
import { UNCONTROLLED_METADATA } from "../../../services/metadata";

describe("BatchEditAboutUncontrolledMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAboutUncontrolledMetadata);
    return renderWithRouterApollo(<Wrapped />);
  });

  it("renders the component", () => {
    expect(screen.getByTestId("uncontrolled-metadata"));
  });

  it("renders expected uncontrolled metadata fields", () => {
    for (let item of UNCONTROLLED_METADATA) {
      expect(screen.getByTestId(item.name));
    }
  });
});
