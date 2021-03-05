import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";
import BatchEditAboutControlledMetadata from "./ControlledMetadata";
import { CONTROLLED_METADATA } from "@js/services/metadata";
import { BatchProvider } from "@js/context/batch-edit-context";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";

describe("BatchEditAboutControlledMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAboutControlledMetadata);

    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <CodeListProvider>
          <Wrapped />
        </CodeListProvider>
      </BatchProvider>,
      {
        mocks: allCodeListMocks,
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
