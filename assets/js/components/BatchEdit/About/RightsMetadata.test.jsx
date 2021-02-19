import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAboutRightsMetadata from "./RightsMetadata";
import { RIGHTS_METADATA } from "../../../services/metadata";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";

describe("BatchEditAboutRightsMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAboutRightsMetadata);
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
    expect(screen.getByTestId("rights-metadata"));
  });

  it("renders expected rights metadata fields", async () => {
    for (let item of RIGHTS_METADATA) {
      expect(screen.getByTestId(item.name));
    }
    expect(screen.getByTestId("license-select"));
  });
});
