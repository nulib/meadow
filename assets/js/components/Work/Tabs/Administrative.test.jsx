import React from "react";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import { mockWork } from "../work.gql.mock";
import WorkTabsAdministrative from "./Administrative";
import { fireEvent, waitFor, screen } from "@testing-library/react";
import {
  getCollectionMock,
  getCollectionsMock,
} from "@js/components/Collection/collection.gql.mock";
import { mockUser } from "../../Auth/auth.gql.mock";
import userEvent from "@testing-library/user-event";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { CodeListProvider } from "@js/context/code-list-context";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

xdescribe("Work Administrative tab component", () => {
  beforeEach(() => {
    renderWithRouterApollo(
      <CodeListProvider>
        <WorkTabsAdministrative work={mockWork} />
      </CodeListProvider>,
      {
        mocks: [getCollectionMock, getCollectionsMock, ...allCodeListMocks],
      }
    );
  });

  it("renders without crashing", async () => {
    // const yo = await screen.findByTestId("work-administrative-form");
    // console.log("yo", yo);

    await waitFor(() => {
      let yo = screen.getByTestId("work-administrative-form");
      expect(yo);
    });
  });

  xit("switches between edit and non edit mode", async () => {
    const editButton = await screen.findByTestId("edit-button");
    expect(editButton);

    userEvent.click(editButton);

    expect(await screen.findByTestId("save-button"));
    expect(await screen.findByTestId("cancel-button"));
  });

  xit("displays form elements only when in edit mode", async () => {
    await waitFor(() => {
      expect(queryByTestId("visibility")).toBeFalsy();
      expect(queryByTestId("project-cycle")).toBeFalsy();
    });

    fireEvent.click(queryByTestId("edit-button"));
    expect(queryByTestId("visibility"));
    expect(queryByTestId("project-cycle"));
  });

  xit("dislays correct work item metadata values", async () => {
    const { getByText, getByTestId, getByDisplayValue } = setupTests();

    await waitFor(() => {
      expect(getByText(/New Project Description/i));
      expect(getByText(/Another Project Description/i));
      expect(getByText(/Project Cycle Name/i));
      expect(getByText(/Started/i));
      expect(getByText(/Collection 1232432 Name/i));
      expect(getByTestId("view-collection-works-button"));
    });

    // And ensure the values transfer to the form elements when in edit mode
    fireEvent.click(getByTestId("edit-button"));
    expect(getByDisplayValue(/Another Project Description/i));
  });
});
