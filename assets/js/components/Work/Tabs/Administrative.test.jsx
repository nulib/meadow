import React from "react";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import { mockWork } from "../work.gql.mock";
import WorkTabsAdministrative from "./Administrative";
import { fireEvent, waitFor, screen } from "@testing-library/react";
import { getCollectionsMock } from "../../Collection/collection.gql.mock";
import {
  codeListPreservationLevelMock,
  codeListStatusMock,
  codeListVisibilityMock,
} from "../controlledVocabulary.gql.mock";
import userEvent from "@testing-library/user-event";

describe("Work Administrative tab component", () => {
  function setupTests() {
    return renderWithRouterApollo(<WorkTabsAdministrative work={mockWork} />, {
      mocks: [
        getCollectionsMock,
        getCollectionsMock,
        codeListPreservationLevelMock,
        codeListStatusMock,
        codeListVisibilityMock,
      ],
    });
  }

  it("renders without crashing", async () => {
    const { getByTestId } = setupTests();
    await waitFor(() => {
      expect(getByTestId("work-administrative-form")).toBeInTheDocument();
    });
  });

  it("switches between edit and non edit mode", async () => {
    const { findByTestId, debug } = setupTests();

    const editButton = await findByTestId("edit-button");
    expect(editButton);

    userEvent.click(editButton);

    expect(await findByTestId("save-button"));
    expect(await findByTestId("cancel-button"));
  });

  it("displays form elements only when in edit mode", async () => {
    const { queryByTestId } = setupTests();

    await waitFor(() => {
      expect(queryByTestId("visibility")).toBeFalsy();
      expect(queryByTestId("project-cycle")).toBeFalsy();
    });

    fireEvent.click(queryByTestId("edit-button"));
    expect(queryByTestId("visibility")).toBeInTheDocument();
    expect(queryByTestId("project-cycle")).toBeInTheDocument();
  });

  it("dislays correct work item metadata values", async () => {
    const { getByText, getByTestId, getByDisplayValue } = setupTests();

    await waitFor(() => {
      expect(getByText(/New Project Description/i)).toBeInTheDocument();
      expect(getByText(/Another Project Description/i)).toBeInTheDocument();
      expect(getByText(/Project Cycle Name/i)).toBeInTheDocument();
      expect(getByText(/Started/i)).toBeInTheDocument();
    });

    // And ensure the values transfer to the form elements when in edit mode
    fireEvent.click(getByTestId("edit-button"));
    expect(
      getByDisplayValue(/Another Project Description/i)
    ).toBeInTheDocument();
  });
});
