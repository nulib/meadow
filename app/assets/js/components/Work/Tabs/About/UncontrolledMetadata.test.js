import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";

import { CodeListProvider } from "@js/context/code-list-context";
import React from "react";
import { UNCONTROLLED_METADATA } from "@js/services/metadata";
import WorkTabsAboutUncontrolledMetadata from "./UncontrolledMetadata";
import { allCodeListMocks } from "../../controlledVocabulary.gql.mock";
import { mockWork } from "@js/components/Work/work.gql.mock";
import { screen } from "@testing-library/react";

describe("Work About tab Uncontrolled Metadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(WorkTabsAboutUncontrolledMetadata, {
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

  it("renders uncontrolled metadata component", async () => {
    expect(await screen.findByTestId("uncontrolled-metadata"));
  });

  it("renders expected uncontrolled metadata fields", async () => {
    for (let item of UNCONTROLLED_METADATA) {
      expect(await screen.findByTestId(item.name));
    }
    expect(await screen.findByTestId("notes"));
  });
});
