import React from "react";
import { waitFor } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookFormControl,
} from "../../../services/testing-helpers";
import BatchEditAboutCoreMetadata from "./CoreMetadata";
import { codeListRightsStatementMock } from "../../Work/controlledVocabulary.gql.mock";
import { BatchProvider } from "../../../context/batch-edit-context";

describe("BatchEditAboutCoreMetadata component", () => {
  function setupTest() {
    const Wrapped = withReactHookFormControl(BatchEditAboutCoreMetadata);
    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <Wrapped />
      </BatchProvider>,
      {
        mocks: [codeListRightsStatementMock],
      }
    );
  }
  it("renders the component", async () => {
    let { queryByTestId } = setupTest();
    await waitFor(() => {
      expect(queryByTestId("core-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected core metadata fields", async () => {
    let { getByTestId } = setupTest();

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
