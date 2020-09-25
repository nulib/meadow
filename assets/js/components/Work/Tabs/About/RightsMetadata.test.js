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

describe("Work About tab Idenfiers Metadata component", () => {
  function setupTests() {
    const Wrapped = withReactHookForm(WorkTabsAboutRightsMetadata, {
      isEditing: true,
      descriptiveMetadata: mockWork.descriptiveMetadata,
    });
    return renderWithRouterApollo(<Wrapped />, {
      mocks: [codeListLicenseMock],
    });
  }

  it("renders rights metadata component", async () => {
    let { queryByTestId } = setupTests();
    await waitFor(() => {
      expect(queryByTestId("rights-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected rights metadata fields ", async () => {
    let { getByTestId } = setupTests(true);

    await waitFor(() => {
      for (let item of RIGHTS_METADATA) {
        expect(getByTestId(item.name)).toBeInTheDocument();
      }
    });
  });
  it("renders license field", async () => {
    let { getByTestId } = setupTests(true);

    await waitFor(() => {
      expect(getByTestId("license")).toBeInTheDocument();
    });
  });
});
