import React from "react";
import {
  mockWork,
  renderWithRouterApollo,
} from "../../../services/testing-helpers";
import WorkTabsAbout from "./About";
import { fireEvent } from "@testing-library/react";
import {
  codeListAuthorityMock,
  codeListMarcRelatorMock,
  codeListRightsStatementMock,
} from "../controlledVocabulary.query.mock";

const mocks = [
  codeListRightsStatementMock,
  codeListAuthorityMock,
  codeListMarcRelatorMock,
];

describe("Work About tab component", () => {
  function setupTests() {
    return renderWithRouterApollo(<WorkTabsAbout work={mockWork} />, { mocks });
  }

  it("renders without crashing", () => {
    expect(setupTests());
  });

  it("switches between edit and non edit mode ", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("edit-button")).toBeInTheDocument();

    fireEvent.click(getByTestId("edit-button"));
    expect(getByTestId("save-button")).toBeInTheDocument();
    expect(getByTestId("cancel-button")).toBeInTheDocument();
  });

  it("displays form elements only when in edit mode", () => {
    const { queryByTestId } = setupTests();

    expect(queryByTestId("description")).toBeFalsy();
    expect(queryByTestId("date-created")).toBeFalsy();

    fireEvent.click(queryByTestId("edit-button"));
    expect(queryByTestId("description")).toBeInTheDocument();
    expect(queryByTestId("date-created")).toBeInTheDocument();
  });

  it("dislays correct work item metadata values", () => {
    const { getByText, getByTestId, getByDisplayValue } = setupTests();

    expect(getByText(/Ima description/i)).toBeInTheDocument();

    // And ensure the values transfer to the form elements when in edit mode
    fireEvent.click(getByTestId("edit-button"));
    expect(getByDisplayValue(/ima description/i)).toBeInTheDocument();
  });
});
