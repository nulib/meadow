import React from "react";
import { waitFor } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookFormControl,
} from "../../../services/testing-helpers";
import BatchEditAboutRightsMetadata from "./RightsMetadata";
import { codeListLicenseMock } from "../../Work/controlledVocabulary.gql.mock";
import { RIGHTS_METADATA } from "../../../services/metadata";

describe("BatchEditAboutRightsMetadata component", () => {
  function setupTest() {
    const Wrapped = withReactHookFormControl(BatchEditAboutRightsMetadata);
    return renderWithRouterApollo(<Wrapped />, {
      mocks: [codeListLicenseMock],
    });
  }
  it("renders the component", async () => {
    let { queryByTestId } = setupTest();
    await waitFor(() => {
      expect(queryByTestId("rights-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected rights metadata fields", async () => {
    let { getByTestId } = setupTest();

    await waitFor(() => {
      for (let item of RIGHTS_METADATA) {
        expect(getByTestId(item.name)).toBeInTheDocument();
      }
      expect(getByTestId("license")).toBeInTheDocument();
    });
  });
});
