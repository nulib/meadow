import React from "react";
import {
  renderWithRouterApollo,
  withReactHookFormControl,
} from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutIdentifiersMetadata from "./IdentifiersMetadata";
import { waitFor } from "@testing-library/react";
import { IDENTIFIER_METADATA } from "../../../../services/metadata";
import { codeListRelatedUrlMock } from "../../controlledVocabulary.gql.mock";

describe("Work About tab Idenfiers Metadata component", () => {
  function setupTests() {
    const Wrapped = withReactHookFormControl(WorkTabsAboutIdentifiersMetadata, {
      isEditing: true,
      descriptiveMetadata: mockWork.descriptiveMetadata,
    });
    return renderWithRouterApollo(<Wrapped />, {
      mocks: [codeListRelatedUrlMock],
    });
  }

  it("renders identifiers metadata component", async () => {
    let { queryByTestId } = setupTests();
    await waitFor(() => {
      expect(queryByTestId("identifiers-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected identifiers metadata fields", async () => {
    let { getByTestId, debug } = setupTests(true);

    await waitFor(() => {
      for (let item of IDENTIFIER_METADATA) {
        expect(getByTestId(item.name)).toBeInTheDocument();
      }
      expect(getByTestId("relatedUrl")).toBeInTheDocument();
    });
  });
});
