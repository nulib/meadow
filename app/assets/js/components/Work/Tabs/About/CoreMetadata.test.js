import React from "react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutCoreMetadata from "./CoreMetadata";
import { waitFor } from "@testing-library/react";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { CodeListProvider } from "@js/context/code-list-context";

describe("WorkTabsAboutCoreMetadata component", () => {
  function setupTests() {
    const Wrapped = withReactHookForm(WorkTabsAboutCoreMetadata, {
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
  }

  it("renders the component", async () => {
    let { queryByTestId } = setupTests();
    await waitFor(() => {
      expect(queryByTestId("core-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected core metadata fields in edit mode", async () => {
    let { getByTestId } = setupTests(true);

    await waitFor(() => {
      const itemTestIds = [
        "title",
        "description",
        "rights-statement",
        "alternate-title",
      ];
      for (let item of itemTestIds) {
        expect(getByTestId(item)).toBeInTheDocument();
      }
    });
  });

  it("shows an AI provenance badge on Alternate Title in display mode", async () => {
    const Wrapped = withReactHookForm(WorkTabsAboutCoreMetadata, {
      isEditing: false,
      descriptiveMetadata: mockWork.descriptiveMetadata,
      provenance: {
        "descriptive_metadata.alternate_title": {
          origin: "ai_generated",
          status: "applied",
        },
      },
    });
    const { getAllByTestId } = renderWithRouterApollo(
      <CodeListProvider>
        <Wrapped />
      </CodeListProvider>,
      { mocks: allCodeListMocks },
    );

    await waitFor(() => {
      const badges = getAllByTestId("provenance-origin-badge");
      expect(badges.some((badge) => badge.textContent === "AI generated")).toBe(
        true,
      );
    });
  });
});
