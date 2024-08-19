import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import ProjectsModalEdit from "./ModalEdit";
import userEvent from "@testing-library/user-event";
import { mockProjects } from "./project.gql.mock";


const submitCallback = jest.fn();
const cancelCallback = jest.fn();

const props = {
  currentProject: mockProjects[0],
  isOpen: true,
  handleUpdate: submitCallback,
  handleClose: cancelCallback,
};

describe("ProjectsModalEdit component", () => {
  beforeEach(() => {
    render(<ProjectsModalEdit {...props} />);
  });

  it("renders the component", () => {
    expect(screen.getByTestId("modal-project-update"));
  });

  it("renders all add form elements with default values", () => {
    expect(screen.getByRole("form"));
    expect(screen.getByLabelText("Title", { exact: false })).toHaveValue("Mock project title");
    expect(screen.getByTestId("submit-button"));
    expect(screen.getByTestId("cancel-button"));
  });

  it("renders a disabled Submit button if no elements have been interacted with", async () => {
    const user = userEvent.setup();

    const submitButtonEl = screen.getByTestId("submit-button");
    expect(submitButtonEl).toBeDisabled();
    await user.type(screen.getByLabelText(/title/i), "something");
    expect(submitButtonEl).not.toBeDisabled();
  });

  it("calls the Cancel and Submit callback functions", async () => {
    const user = userEvent.setup();
    const expectedFormPostData = {
      title: "foo bar",
    };
    const labelEl = screen.getByLabelText(/title/i);

    await user.clear(labelEl);

    await user.type(labelEl, "foo bar");
    await user.click(screen.getByTestId("submit-button"));
    await waitFor(() => {
      expect(submitCallback).toHaveBeenCalledWith(expectedFormPostData);
    });

    await user.click(screen.getByTestId("cancel-button"));
    expect(cancelCallback).toHaveBeenCalled();
  });
});
