import React from "react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";
import { mockWork } from "@js/components/Work/work.gql.mock";
import WorkTabsAboutRightsMetadata from "./RightsMetadata";
import { RIGHTS_METADATA } from "@js/services/metadata";
import { screen } from "@testing-library/react";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";

describe("Work About tab Idenfiers Metadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(WorkTabsAboutRightsMetadata, {
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
