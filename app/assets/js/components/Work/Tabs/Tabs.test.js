import React from "react";
import WorkTabs from "./Tabs";
import { fireEvent, waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import { mockWork } from "../work.gql.mock";
import { iiifServerUrlMock } from "../../IIIF/iiif.gql.mock";
import { allCodeListMocks } from "../controlledVocabulary.gql.mock";
import {
  getCollectionMock,
  getCollectionsMock,
} from "@js/components/Collection/collection.gql.mock";
import {
  getCurrentUserMock,
  getViewerMock,
  mockUser,
} from "@js/components/Auth/auth.gql.mock";
const mocks = [
  ...allCodeListMocks,
  getCollectionMock,
  getCollectionsMock,
  iiifServerUrlMock,
  getCurrentUserMock,
];
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

xdescribe("Tabs component", () => {
  function setupTests() {
    return renderWithRouterApollo(<WorkTabs work={mockWork} />, { mocks });
  }

  function setUpViewerTests() {
    return renderWithRouterApollo(<WorkTabs work={mockWork} />, {
      mocks: [
        ...allCodeListMocks,
        getCollectionMock,
        getCollectionsMock,
        iiifServerUrlMock,
        getViewerMock,
      ],
    });
  }

  it("renders without crashing", () => {
    expect(setupTests()).toBeTruthy();
  });

  it("renders tab section and all four tabs: About, Administrative, Structure, and Preservation", async () => {
    const { getByTestId } = setupTests();

    await waitFor(() => {
      expect(getByTestId("tabs"));
      expect(getByTestId("tab-about"));
      expect(getByTestId("tab-administrative"));
      expect(getByTestId("tab-structure"));
      expect(getByTestId("tab-preservation"));
    });
  });

  it("renders About tab content by default", async () => {
    const { queryByTestId } = setupTests();

    await waitFor(() => {
      expect(queryByTestId("tab-about-content")).toBeVisible();
      expect(queryByTestId("structure-content")).toBeNull();
    });
  });

  it("renders a tab active when clicking on a tab nav item", async () => {
    const { queryByTestId, debug } = setupTests();

    await waitFor(() => {
      expect(queryByTestId("tab-about-content")).not.toHaveClass("is-hidden");

      fireEvent.click(queryByTestId("tab-administrative"));

      expect(queryByTestId("tab-administrative-content")).not.toHaveClass(
        "is-hidden"
      );
      expect(queryByTestId("tab-about-content")).toHaveClass("is-hidden");

      fireEvent.click(queryByTestId("tab-preservation"));

      expect(queryByTestId("tab-about-content")).toHaveClass("is-hidden");
      expect(queryByTestId("tab-administrative-content")).toHaveClass(
        "is-hidden"
      );
      expect(queryByTestId("tab-structure-content")).toHaveClass("is-hidden");
      expect(queryByTestId("tab-preservation-content")).not.toHaveClass(
        "is-hidden"
      );
    });
  });

  it("hides preservation tab when user is of viewer role", async () => {
    const { queryByTestId } = setUpViewerTests();
    expect(queryByTestId("tab-preservation")).not.toBeInTheDocument();
    expect(queryByTestId("tab-preservation-content")).not.toBeInTheDocument();
  });
});
