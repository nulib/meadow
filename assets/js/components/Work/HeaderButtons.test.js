import React from "react";
import WorkHeaderButtons from "./HeaderButtons";
import { fireEvent, render } from "@testing-library/react";

const mockHandleCreateSharableBtnClick = jest.fn();
const mockHandlePublishClick = jest.fn();

const props = {
  handleCreateSharableBtnClick: mockHandleCreateSharableBtnClick,
  handlePublishClick: mockHandlePublishClick,
  hasCollection: true,
  published: false,
};

describe("WorkHeaderButtons component", () => {
  it("renders the component", () => {
    const { getByTestId } = render(<WorkHeaderButtons />);
    expect(getByTestId("work-header-buttons"));
  });

  it("renders an active Publish button", () => {
    const { getByTestId } = render(<WorkHeaderButtons {...props} />);
    const el = getByTestId("publish-button");

    expect(el).not.toBeDisabled();

    fireEvent.click(el);
    expect(mockHandlePublishClick).toHaveBeenCalled();
  });

  it("renders an inactive Publish button", () => {
    let newProps = { ...props, hasCollection: false };
    const { getByTestId } = render(<WorkHeaderButtons {...newProps} />);
    expect(getByTestId("publish-button")).toBeDisabled();
  });

  it("renders an Unpublish button", () => {
    let newProps = { ...props, published: true };
    const { getByText } = render(<WorkHeaderButtons {...newProps} />);
    expect(getByText(/unpublish/i));
  });

  it("renders sharable link button which fires a callback function", () => {
    const { getByTestId } = render(<WorkHeaderButtons {...props} />);
    const el = getByTestId("button-sharable-link");
    fireEvent.click(el);
    expect(mockHandleCreateSharableBtnClick).toHaveBeenCalled();
  });
});
