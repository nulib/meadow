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

const mocks = [getCollectionMock, getCollectionsMock];
const mockHandleViewAllWorksFn = jest.fn();
const props = {
  collection: collectionMock,
  handleViewAllWorksClick: mockHandleViewAllWorksFn,
  isEditing: true,
  workId: "ABC123",
};

describe("WorkTabsAdministrativeCollection component", () => {
  it("renders", async () => {
    const Wrapped = withReactHookForm(WorkTabsAdministrativeCollection, props);
    renderWithApollo(<Wrapped />, {
      mocks,
    });
    expect(await screen.findByTestId("collection-box"));
  });

  it("displays the Collection select form element when in edit mode", async () => {
    const Wrapped = withReactHookForm(WorkTabsAdministrativeCollection, props);
    renderWithApollo(<Wrapped />, {
      mocks,
    });
    // The select form element
    expect(await screen.findByTestId("collection-select"));

    // The element which shows current collection (non-edit mode)
    expect(screen.queryByTestId("view-collection-works-button")).toBeNull();
  });

  it("displays the selected Collection (in non-edit mode) and handles being clicked", async () => {
    const Wrapped = withReactHookForm(WorkTabsAdministrativeCollection, {
      ...props,
      isEditing: false,
    });
    renderWithApollo(<Wrapped />, {
      mocks,
    });

    const collectionLinkEl = await screen.findByTestId(
      "view-collection-works-button"
    );
    expect(collectionLinkEl).toHaveTextContent("Great collection");
    userEvent.click(collectionLinkEl);
    expect(mockHandleViewAllWorksFn).toHaveBeenCalled();
  });

  it("displays a toggle switch only when not editing metadata", async () => {
    const WrappedIsEditing = withReactHookForm(
      WorkTabsAdministrativeCollection,
      props
    );
    renderWithApollo(<WrappedIsEditing />, {
      mocks,
    });
    await waitFor(() =>
      expect(screen.queryByTestId("featured-image-toggle")).toBeNull()
    );

    const WrappedNotEditing = withReactHookForm(
      WorkTabsAdministrativeCollection,
      { ...props, isEditing: false }
    );
    renderWithApollo(<WrappedNotEditing />, {
      mocks,
    });
    const toggleEl2 = await screen.findByTestId("featured-image-toggle");
    expect(toggleEl2);
  });

  it("renders toggle as checked when Work is the Collection image", async () => {
    const WrappedNotEditing = withReactHookForm(
      WorkTabsAdministrativeCollection,
      { ...props, isEditing: false }
    );
    renderWithApollo(<WrappedNotEditing />, {
      mocks,
    });
    const toggleEl = await screen.findByTestId("featured-image-toggle");
    expect(toggleEl).toBeChecked();
  });

  it("renders toggle as not checked when Work is not the Collection image", async () => {
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
});
