import React from "react";
import { screen } from "@testing-library/react";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../../services/testing-helpers";
import BatchEditAdministrativeProjectMetadata from "./ProjectMetadata";
import { BatchProvider } from "../../../context/batch-edit-context";

describe("BatchEditAdministrativeProjectMetadata component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAdministrativeProjectMetadata);
    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <Wrapped />
      </BatchProvider>
    );
  });

  it("renders the component", () => {
    expect(screen.getByTestId("project-metadata"));
  });

  it("renders expected project metadata fields", () => {
    const itemTestIds = [
      "projectDesc",
      "projectManager",
      "projectName",
      "projectProposer",
      "projectTaskNumber",
      "projectCycle",
    ];
    for (let item of itemTestIds) {
      expect(screen.getByTestId(item)).toBeInTheDocument();
    }
  });
});
