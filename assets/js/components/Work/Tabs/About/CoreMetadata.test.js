import React from "react";
import {
  renderWithRouterApollo,
  withReactHookFormControl,
} from "../../../../services/testing-helpers";
import { mockWork } from "../../work.gql.mock";
import WorkTabsAboutCoreMetadata from "./CoreMetadata";
import { waitFor } from "@testing-library/react";
import { codeListRightsStatementMock } from "../../controlledVocabulary.gql.mock";

describe("WorkTabsAboutCoreMetadata component", () => {
  function setupTests() {
    const Wrapped = withReactHookFormControl(WorkTabsAboutCoreMetadata, {
      isEditing: true,
      descriptiveMetadata: mockWork.descriptiveMetadata,
    });
    return renderWithRouterApollo(<Wrapped />, {
      mocks: [codeListRightsStatementMock],
    });
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
        "date-created",
        "alternate-title",
      ];
      for (let item of itemTestIds) {
        expect(getByTestId(item)).toBeInTheDocument();
      }
    });
  });
});
