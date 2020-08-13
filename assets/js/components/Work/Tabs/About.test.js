import React from "react";
import {
  renderWithRouterApollo,
  setupCachedCodeListsLocalStorage,
} from "../../../services/testing-helpers";
import { mockWork } from "../work.gql.mock";
import WorkTabsAbout from "./About";
import { fireEvent, waitFor } from "@testing-library/react";
import {
  codeListLicenseMock,
  codeListRelatedUrlMock,
  codeListRightsStatementMock,
} from "../controlledVocabulary.gql.mock";

describe("Work About tab component", () => {
  function setupTests() {
    setupCachedCodeListsLocalStorage();

    return renderWithRouterApollo(<WorkTabsAbout work={mockWork} />, {
      mocks: [
        codeListLicenseMock,
        codeListRelatedUrlMock,
        codeListRightsStatementMock,
      ],
    });
  }

  it("renders without crashing", async () => {
    const { getByTestId } = setupTests();
    await waitFor(() => {
      expect(getByTestId("work-about-form")).toBeInTheDocument();
    });
  });

  it("switches between edit and non edit mode", async () => {
    const { getByTestId, debug } = setupTests();

    await waitFor(() => {
      expect(getByTestId("edit-button")).toBeInTheDocument();
      //debug();
    });

    fireEvent.click(getByTestId("edit-button"));
    expect(getByTestId("save-button")).toBeInTheDocument();
    expect(getByTestId("cancel-button")).toBeInTheDocument();
  });

  it("displays form elements only when in edit mode", async () => {
    const { queryByTestId } = setupTests();

    await waitFor(() => {
      expect(queryByTestId("description")).toBeFalsy();
      expect(queryByTestId("date-created")).toBeFalsy();
    });

    fireEvent.click(queryByTestId("edit-button"));
    expect(queryByTestId("description")).toBeInTheDocument();
    expect(queryByTestId("date-created")).toBeInTheDocument();
  });

  it("displays readonly box when in edit mode", async () => {
    const { queryByTestId } = setupTests();

    await waitFor(() => {
      expect(queryByTestId("uneditable-metadata")).toBeFalsy();
    });

    fireEvent.click(queryByTestId("edit-button"));
    expect(queryByTestId("uneditable-metadata")).toBeInTheDocument();
  });

  it("dislays correct work item metadata values", async () => {
    const { getByText, getByTestId, getByDisplayValue } = setupTests();

    await waitFor(() => {
      expect(getByText(/Work description here/i)).toBeInTheDocument();
    });

    // And ensure the values transfer to the form elements when in edit mode
    fireEvent.click(getByTestId("edit-button"));
    expect(getByDisplayValue(/Work description here/i)).toBeInTheDocument();
  });
});
