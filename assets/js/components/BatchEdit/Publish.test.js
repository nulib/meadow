import React from "react";
import BatchEditPublish from "@js/components/BatchEdit/Publish";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const mockClick = jest.fn();
const props = {
  batchPublish: {
    publish: false,
    unpublish: false,
  },
  setBatchPublish: mockClick,
};

describe("BatchEditPublish component", () => {
  beforeEach(() => {
    render(<BatchEditPublish {...props} />);
  });

  it("renders", () => {
    expect(screen.getByTestId("batch-edit-publish-wrapper"));
  });

  it("renders publish and unpublish checkboxes", () => {
    expect(screen.getByLabelText("Publish works"));
    expect(screen.getByLabelText("Unpublish works"));
  });

  it("allows only one checkbox to be selected", () => {
    const publishCheckbox = screen.getByLabelText("Publish works");
    const unPublishCheckbox = screen.getByLabelText("Unpublish works");
    userEvent.click(publishCheckbox);
    userEvent.click(unPublishCheckbox);
    expect(publishCheckbox).not.toBeChecked();

    userEvent.click(publishCheckbox);
    expect(unPublishCheckbox).not.toBeChecked();
  });
});
