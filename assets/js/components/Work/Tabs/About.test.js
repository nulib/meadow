import React from "react";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import { mockWork } from "../work.gql.mock";
import WorkTabsAbout from "./About";
import { fireEvent, waitFor, screen } from "@testing-library/react";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { CodeListProvider } from "@js/context/code-list-context";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";

describe("Work About tab component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <AuthProvider>
        <CodeListProvider>
          <WorkTabsAbout work={mockWork} />
        </CodeListProvider>
      </AuthProvider>,
      {
        mocks: [getCurrentUserMock, ...allCodeListMocks],
      }
    );
  });

  it("renders without crashing", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("work-about-form"));
    });
  });

  it("switches between edit and non edit mode", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("edit-button"));
      //debug();
    });

    fireEvent.click(screen.queryByTestId("edit-button"));
    expect(screen.getByTestId("save-button"));
    expect(screen.getByTestId("cancel-button"));
  });

  it("displays form elements only when in edit mode", async () => {
    await waitFor(() => {
      expect(screen.queryByTestId("description")).toBeFalsy();
      expect(screen.queryByTestId("alternate-title")).toBeFalsy();
    });

    fireEvent.click(screen.queryByTestId("edit-button"));
    expect(screen.queryByTestId("description"));
    expect(screen.queryByTestId("alternate-title"));
  });

  it("displays readonly box when in edit mode", async () => {
    await waitFor(() => {
      expect(screen.queryByTestId("uneditable-metadata")).toBeFalsy();
    });

    fireEvent.click(screen.queryByTestId("edit-button"));
    expect(screen.queryByTestId("uneditable-metadata"));
  });

  it("displays correct work item metadata values", async () => {
    await waitFor(() => {
      expect(screen.getByText(/Work description here/i));
    });

    fireEvent.click(screen.queryByTestId("edit-button"));
    expect(screen.getByDisplayValue(/Work description here/i));
  });
});
