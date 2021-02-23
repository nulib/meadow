import React from "react";
import WorkHeaderButtons from "./HeaderButtons";
import { fireEvent, render, waitFor } from "@testing-library/react";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const mockHandleCreateSharableBtnClick = jest.fn();
const mockHandlePublishClick = jest.fn();

const props = {
  handleCreateSharableBtnClick: mockHandleCreateSharableBtnClick,
  handlePublishClick: mockHandlePublishClick,
  hasCollection: true,
  published: false,
};

describe("WorkHeaderButtons component", () => {
  function setUpTests(props) {
    return render(<WorkHeaderButtons {...props} />);
  }
  it("renders the component", async () => {
    const { getByTestId } = setUpTests();
    await waitFor(() => {
      expect(getByTestId("work-header-buttons"));
    });
  });

  it("renders an active Publish button", async () => {
    const { getByTestId } = setUpTests(props);

    await waitFor(() => {
      const el = getByTestId("publish-button");
      expect(el).not.toBeDisabled();
      fireEvent.click(el);
    });

    expect(mockHandlePublishClick).toHaveBeenCalled();
  });

  it("renders an inactive Publish button", async () => {
    let newProps = { ...props, hasCollection: false };
    const { getByTestId } = setUpTests(newProps);
    await waitFor(() => {
      expect(getByTestId("publish-button")).toBeDisabled();
    });
  });

  it("renders an Unpublish button", async () => {
    let newProps = { ...props, published: true };
    const { getByText } = setUpTests(newProps);

    await waitFor(() => {
      const unpublishBtn = getByText(/unpublish/i);
      expect(unpublishBtn);
      expect(unpublishBtn).not.toBeDisabled();
    });
  });

  it("renders an enabled Unpublish button even if a Work does not have a Collection", async () => {
    let newProps = { ...props, hasCollection: false, published: true };
    const { getByText } = setUpTests(newProps);

    await waitFor(() => {
      expect(getByText(/unpublish/i)).not.toBeDisabled();
    });
  });

  it("renders sharable link button which fires a callback function", async () => {
    const { getByTestId } = setUpTests(props);

    await waitFor(() => {
      const el = getByTestId("button-sharable-link");
      fireEvent.click(el);
      expect(mockHandleCreateSharableBtnClick).toHaveBeenCalled();
    });
  });
});
