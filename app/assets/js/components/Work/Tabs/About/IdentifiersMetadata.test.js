import React from "react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutIdentifiersMetadata from "./IdentifiersMetadata";
import { screen } from "@testing-library/react";
import { IDENTIFIER_METADATA } from "../../../../services/metadata";
import { allCodeListMocks } from "../../controlledVocabulary.gql.mock";
import { CodeListProvider } from "@js/context/code-list-context";

describe("Work About Tab Identifiers metadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(WorkTabsAboutIdentifiersMetadata, {
      isEditing: true,
      descriptiveMetadata: mockWork.descriptiveMetadata,
    });
    return renderWithRouterApollo(
      <CodeListProvider>
        <Wrapped />
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      }
    );
  });

  it("renders identifiers metadata component", async () => {
    expect(await screen.findByTestId("identifiers-metadata"));
  });

  it("renders expected identifiers metadata fields", async () => {
    for (let item of IDENTIFIER_METADATA) {
      expect(await screen.findByTestId(item.name));
    }
    expect(await screen.findByTestId("relatedUrl"));
  });
});
