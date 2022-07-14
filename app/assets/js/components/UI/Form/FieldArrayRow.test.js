import React from "react";
import { renderWithReactHookForm } from "../../../services/testing-helpers";
import UIFormFieldArrayRow from "./FieldArrayRow";
import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const mockRemoveFn = jest.fn();

const name = "creator";
const props = {
  handleRemoveClick: mockRemoveFn,
  index: 0,
  item: {
    id: "03018287-82e1-47b6-9c51-c4b409495061",
    metadataItem: "New Creator",
  },
  label: "Creator",
  name,
};

describe("UIFormFieldArrayRow component", () => {
  // beforeEach(() => {
  //   renderWithReactHookForm(<UIFormFieldArrayRow {...props} />);
  // });

  it("renders the row", () => {
    renderWithReactHookForm(<UIFormFieldArrayRow {...props} />);
    expect(screen.getByTestId("field-array-row"));
  });

  it("renders a form input with the correct form name in React Hook Form array format", () => {
    renderWithReactHookForm(<UIFormFieldArrayRow {...props} />);
    const inputEl = screen.getByTestId("input-field-array");
    expect(inputEl.name).toEqual(`${name}[0].metadataItem`);
  });

  it("renders a proper default value", () => {
    renderWithReactHookForm(<UIFormFieldArrayRow {...props} />);
    expect(screen.getByDisplayValue("New Creator"));
  });

  it("renders a remove button and handles the click event", async () => {
    const user = userEvent.setup();
    renderWithReactHookForm(<UIFormFieldArrayRow {...props} />);
    const buttonEl = screen.getByTestId("button-delete-field-array-row");

    await user.click(buttonEl);
    expect(mockRemoveFn).toHaveBeenCalledWith(props.index);
  });

  //TODO: Figure out why manually setting an error on the element is not working in the test
  xit("renders any errors on the row if errors exist", async () => {
    props.item.metadataItem = "";
    const result = renderWithReactHookForm(<UIFormFieldArrayRow {...props} />, {
      toPassBack: ["setError"],
    });

    const { setError } = result.reactHookFormMethods;

    await waitFor(() => {
      setError(`${name}[0].metadataItem`, {
        type: "required",
        message: "Creator field is required",
      });
    });

    expect(screen.getByTestId("input-field-array")).toHaveClass("is-danger");
    expect(screen.getByTestId("input-errors")).toBeInTheDocument();
    expect(screen.getByText("Creator field is required"));
  });
});
