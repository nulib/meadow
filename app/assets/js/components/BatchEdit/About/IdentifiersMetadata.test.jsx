import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAboutIdentifiersMetadata from "./IdentifiersMetadata";
import { IDENTIFIER_METADATA } from "../../../services/metadata";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { CodeListProvider } from "@js/context/code-list-context";

describe("BatchEditAboutIdentifiersMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAboutIdentifiersMetadata);
    return renderWithRouterApollo(
      <CodeListProvider>
        <Wrapped />
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      }
    );
  });

  it("renders the component", async () => {
    expect(await screen.findByTestId("identifiers-metadata"));
  });

  it("renders expected identifiers metadata fields", async () => {
    for (let item of IDENTIFIER_METADATA) {
      expect(await screen.findByTestId(item.name));
    }
    expect(await screen.findByTestId("relatedUrl"));
  });
});
