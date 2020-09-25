import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAboutCoreMetadata from "./CoreMetadata";
import { codeListRightsStatementMock } from "../../Work/controlledVocabulary.gql.mock";
import { BatchProvider } from "../../../context/batch-edit-context";

describe("BatchEditAboutCoreMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAboutCoreMetadata);
    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <Wrapped />
      </BatchProvider>,
      {
        mocks: [codeListRightsStatementMock],
      }
    );
  });

  it("renders the component", () => {
    expect(screen.getByTestId("core-metadata"));
  });

  it("renders expected core metadata fields", () => {
    const itemTestIds = [
      "title",
      "description",
      "rights-statement",
      "date-created",
      "alternate-title",
    ];
    for (let item of itemTestIds) {
      expect(screen.getByTestId(item)).toBeInTheDocument();
    }
  });
});
