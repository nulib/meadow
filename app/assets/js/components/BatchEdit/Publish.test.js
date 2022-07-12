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
    expect(screen.getByLabelText("Published"));
    expect(screen.getByLabelText("Unpublished"));
  });

  it("allows only one checkbox to be selected", async () => {
    const user = userEvent.setup();

    const publishCheckbox = screen.getByLabelText("Published");
    const unPublishCheckbox = screen.getByLabelText("Unpublished");
    await user.click(publishCheckbox);
    await user.click(unPublishCheckbox);
    expect(publishCheckbox).not.toBeChecked();

    await user.click(publishCheckbox);
    expect(unPublishCheckbox).not.toBeChecked();
  });
});
