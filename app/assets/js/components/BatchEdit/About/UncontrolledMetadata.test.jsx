import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAboutUncontrolledMetadata from "./UncontrolledMetadata";
import { UNCONTROLLED_METADATA } from "../../../services/metadata";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { CodeListProvider } from "@js/context/code-list-context";

describe("BatchEditAboutUncontrolledMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAboutUncontrolledMetadata);
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
    expect(await screen.findByTestId("uncontrolled-metadata"));
  });

  it("renders expected uncontrolled metadata fields", async () => {
    for (let item of UNCONTROLLED_METADATA) {
      expect(await screen.findByTestId(item.name));
    }
    expect(await screen.findByTestId("notes"));
  });
});
