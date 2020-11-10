import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAdministrativeGeneral from "./General";
import { BatchProvider } from "../../../context/batch-edit-context";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";

describe("BatchEditAdministrativeGeneral component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAdministrativeGeneral);
    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <CodeListProvider>
          <Wrapped />
        </CodeListProvider>
      </BatchProvider>,
      { mocks: allCodeListMocks }
    );
  });

  it("renders the component", () => {
    expect(screen.getByTestId("project-status-metadata"));
  });

  it("renders expected project status metadata fields", () => {
    const itemTestIds = [
      "preservationLevel",
      "status",
      "visibility",
      "libraryUnit",
    ];
    for (let item of itemTestIds) {
      expect(screen.getByTestId(item)).toBeInTheDocument();
    }
  });
});
