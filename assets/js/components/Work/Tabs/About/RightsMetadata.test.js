import React from "react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutRightsMetadata from "./RightsMetadata";
import { waitFor } from "@testing-library/react";
import { codeListLicenseMock } from "../../controlledVocabulary.gql.mock";
import { RIGHTS_METADATA } from "../../../../services/metadata";
import { screen } from "@testing-library/react";

describe("Work About tab Idenfiers Metadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(WorkTabsAboutRightsMetadata, {
      isEditing: true,
      descriptiveMetadata: mockWork.descriptiveMetadata,
    });
    return renderWithRouterApollo(<Wrapped />, {
      mocks: [codeListLicenseMock],
    });
  });

  it("renders expected rights metadata fields", async () => {
    for (let item of RIGHTS_METADATA) {
      expect(await screen.findByTestId(item.name));
    }
  });

  it("renders rights metadata component", async () => {
    expect(await screen.findByTestId("rights-metadata"));
  });

  it("renders license field", async () => {
    expect(await screen.findByTestId("license"));
  });
  it("renders terms of use field", async () => {
    expect(await screen.findByTestId("input-terms-of-use"));
  });
});
