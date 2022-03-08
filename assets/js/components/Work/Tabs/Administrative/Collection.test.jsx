import React from "react";
import WorkTabsAdministrativeCollection from "@js/components/Work/Tabs/Administrative/Collection";
import { screen, waitFor } from "@testing-library/react";
import {
  getCollectionMock,
  getCollectionsMock,
  collectionMock,
} from "@js/components/Collection/collection.gql.mock";
import {
  renderWithApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";
import userEvent from "@testing-library/user-event";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { mockUser } from "@js/components/Auth/auth.gql.mock";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const mocks = [getCollectionMock, getCollectionsMock];
const mockHandleViewAllWorksFn = jest.fn();
const props = {
  collection: collectionMock,
  handleViewAllWorksClick: mockHandleViewAllWorksFn,
  isEditing: true,
  workId: collectionMock.representativeWork.id,
};

describe("WorkTabsAdministrativeCollection component", () => {
  it("renders", async () => {
    const Wrapped = withReactHookForm(WorkTabsAdministrativeCollection, props);
    renderWithApollo(<Wrapped />, {
      mocks,
    });
    expect(await screen.findByTestId("collection-box"));
  });

  describe("in edit mode", () => {
    it("displays the Collection select form element", async () => {
      const Wrapped = withReactHookForm(
        WorkTabsAdministrativeCollection,
        props
      );
      renderWithApollo(<Wrapped />, {
        mocks,
      });
      // The select form element
      expect(await screen.findByTestId("collection-select"));

      // These elements should not be present in Edit mode
      expect(screen.queryByTestId("view-collection-works-button")).toBeNull();
      expect(screen.queryByTestId("featured-image-toggle")).toBeNull();
    });
  });

  describe("in non-edit mode", () => {
    beforeEach(() => {
      const Wrapped = withReactHookForm(WorkTabsAdministrativeCollection, {
        ...props,
        isEditing: false,
      });
      renderWithApollo(<Wrapped />, {
        mocks,
      });
    });

    it("displays selected Collection link and handles being clicked", async () => {
      const collectionLinkEl = await screen.findByTestId(
        "view-collection-works-button"
      );
      expect(collectionLinkEl).toHaveTextContent("Great collection");
      userEvent.click(collectionLinkEl);
      expect(mockHandleViewAllWorksFn).toHaveBeenCalled();
    });

    it("displays a toggle switch for representative Collection image, when the Work is part of a Collection", async () => {
      const toggleEl = await screen.findByTestId("featured-image-toggle");
      expect(toggleEl);
    });

    it("toggle is checked when Work is the Collection image", async () => {
      const toggleEl = await screen.findByTestId("featured-image-toggle");
      expect(toggleEl).toBeChecked();
    });
  });

  describe("non-edit mode Collection image toggle switch", () => {
    it("is not checked when Work is not the Collection image", async () => {
      const WrappedNotEditing = withReactHookForm(
        WorkTabsAdministrativeCollection,
        { ...props, isEditing: false, workId: "FOOBAZ" }
      );
      renderWithApollo(<WrappedNotEditing />, {
        mocks,
      });
      const toggleEl = await screen.findByTestId("featured-image-toggle");
      expect(toggleEl).not.toBeChecked();
    });

    it("is not present when the Work isn't part of a Collection", async () => {
      const Wrapped = withReactHookForm(WorkTabsAdministrativeCollection, {
        ...props,
        isEditing: false,
        workId: "COULD_BE_ANYTHING",
        collection: null,
      });
      renderWithApollo(<Wrapped />, {
        mocks,
      });
      await waitFor(() => {
        const toggleEl = screen.queryByTestId("featured-image-toggle");
        expect(toggleEl).toBeNull();
      });
    });
  });
});
