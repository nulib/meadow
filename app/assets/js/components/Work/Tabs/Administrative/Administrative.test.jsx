import {
  MOCK_COLLECTION_ID,
  getCollectionMock,
  getCollectionsMock,
} from "@js/components/Collection/collection.gql.mock";
import { screen, waitFor } from "@testing-library/react";

import { CodeListProvider } from "@js/context/code-list-context";
import React from "react";
import WorkTabsAdministrative from "./Administrative";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { formatDate } from "@js/services/helpers";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { mockWork } from "../../work.gql.mock";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import userEvent from "@testing-library/user-event";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

// To properly mock the GraphQL response, need to override "mockWork"'s collection
// with another Collection id
mockWork.collection.id = MOCK_COLLECTION_ID;

describe("Work Administrative tab component", () => {
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
    expect(await screen.findByTestId("work-administrative-form"));
  });

  it("switches between edit and non edit mode", async () => {
    const user = userEvent.setup();
    const editButton = await screen.findByTestId("edit-button");
    expect(editButton);

    await user.click(editButton);

    expect(await screen.findByTestId("save-button"));
    expect(await screen.findByTestId("cancel-button"));
  });

  it("displays form elements only when in edit mode", async () => {
    const user = userEvent.setup();
    await waitFor(() => {
      expect(screen.queryByTestId("visibility")).toBeFalsy();
      expect(screen.queryByTestId("project-cycle")).toBeFalsy();
    });

    await user.click(screen.queryByTestId("edit-button"));
    expect(screen.queryByTestId("visibility"));
    expect(screen.queryByTestId("project-cycle"));
  });

  it("displays correct Project metadata values", async () => {
    const user = userEvent.setup();
    const description = /New Project Description/i;
    const cycleName = /Project Cycle Name/i;
    await waitFor(() => {
      const descriptionEl = screen.getByText(description);
      expect(descriptionEl.tagName).not.toEqual(/a/i);
      expect(screen.getByText(description));
      expect(screen.getByText(cycleName));
      expect(screen.getByText(/Started/i));
      expect(screen.getByText(/Collection 1232432 Name/i));
      expect(screen.getByTestId("view-collection-works-button"));
    });

    // And ensure the values transfer to the form elements when in edit mode
    await user.click(screen.getByTestId("edit-button"));
    expect(screen.getByDisplayValue(description));
    expect(screen.getByDisplayValue(cycleName));
  });

  it("displays correct Project metadata values", async () => {
    const insertedAtEl = await screen.findByTestId("inserted-at-label");
    const updatedAtEl = await screen.findByTestId("updated-at-label");
    expect(insertedAtEl).toHaveTextContent(formatDate("2019-02-04T19:16:16"));
    expect(updatedAtEl).toHaveTextContent(formatDate("2019-12-02T22:22:16"));
  });
});
