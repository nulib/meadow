import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";

import { CodeListProvider } from "@js/context/code-list-context";
import { RIGHTS_METADATA } from "@js/services/metadata";
import React from "react";
import WorkTabsAboutRightsMetadata from "./RightsMetadata";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { mockWork } from "@js/components/Work/work.gql.mock";
import { screen } from "@testing-library/react";

describe.only("Work About tab Idenfiers Metadata component", () => {
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
      },
    );
  });

  it("renders expected rights metadata fields", async () => {
    for (let item of RIGHTS_METADATA) {
      expect(await screen.findByTestId(item.name)).toBeInTheDocument();
    }
  });

  it("renders rights metadata component", async () => {
    expect(await screen.findByTestId("rights-metadata")).toBeInTheDocument();
  });

  it("renders license field", async () => {
    expect(await screen.findByTestId("license")).toBeInTheDocument();
  });
  it("renders terms of use field", async () => {
    expect(await screen.findByTestId("terms-of-use"));
  });
});
