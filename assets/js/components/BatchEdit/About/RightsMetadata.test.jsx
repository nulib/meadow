import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAboutRightsMetadata from "./RightsMetadata";
import { codeListLicenseMock } from "../../Work/controlledVocabulary.gql.mock";
import { RIGHTS_METADATA } from "../../../services/metadata";

describe("BatchEditAboutRightsMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAboutRightsMetadata);
    return renderWithRouterApollo(<Wrapped />, {
      mocks: [codeListLicenseMock],
    });
  });

  it("renders the component", async () => {
    expect(screen.getByTestId("rights-metadata"));
  });

  it("renders expected rights metadata fields", async () => {
    for (let item of RIGHTS_METADATA) {
      expect(screen.getByTestId(item.name));
    }
    expect(screen.getByTestId("license"));
  });
});
