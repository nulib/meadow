import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";

import BatchEditAboutRightsMetadata from "./RightsMetadata";
import { CodeListProvider } from "@js/context/code-list-context";
import { RIGHTS_METADATA } from "@js/services/metadata";
import React from "react";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { screen } from "@testing-library/react";

describe("BatchEditAboutRightsMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAboutRightsMetadata);
    return renderWithRouterApollo(
      <CodeListProvider>
        <Wrapped />
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      },
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

  it("renders Terms of Use field", async () => {
    expect(screen.getByTestId("terms-of-use"));
  });
});
