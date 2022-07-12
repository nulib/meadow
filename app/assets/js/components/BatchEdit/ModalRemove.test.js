import React from "react";
import BatchEdiModalRemove from "@js/components/BatchEdit/ModalRemove";
import { render, screen, within } from "@testing-library/react";
import { BatchProvider } from "@js/context/batch-edit-context";
import userEvent from "@testing-library/user-event";

const props = {
  closeModal: jest.fn(),
  currentRemoveField: { label: "Genre", name: "genre" },
  isRemoveModalOpen: true,
  items: [
    {
      doc_count: 25,
      key: "http://vocab.getty.edu/aat/300128343||black-and-white negatives|",
    },
    {
      doc_count: 24,
      key: "http://vocab.getty.edu/aat/300033618||paintings (visual works)|",
    },
    {
      doc_count: 15,
      key: "http://vocab.getty.edu/aat/300054156||architecture (discipline)|",
    },
  ],
};

describe("BatchEditModalRemove component", () => {
  function renderComponent(restProps) {
    const allProps = { ...props, ...restProps };
    return render(
      <BatchProvider>
        <BatchEdiModalRemove {...allProps} />
      </BatchProvider>
    );
  }

  it("displays with a visibility flag", () => {
    renderComponent();
    expect(screen.getByTestId("modal-remove")).toHaveClass("is-active");
  });

  it("does not display with a visibility flag set to false", () => {
    renderComponent({ isRemoveModalOpen: false });
    expect(screen.getByTestId("modal-remove")).not.toHaveClass("is-active");
  });

  it("renders the current field label as title", () => {
    renderComponent();
    expect(screen.getByTestId("field-title")).toHaveTextContent(
      props.currentRemoveField.label
    );
  });

  it("renders remove checkboxes with appropriate values", () => {
    renderComponent();
    const checkboxFields = screen.getAllByTestId("checkbox-field");
    expect(checkboxFields).toHaveLength(3);

    let utils = within(checkboxFields[0]);
    utils.getByText(/^architecture \(discipline\)$/i);
    utils.getByText("http://vocab.getty.edu/aat/300054156", { exact: false });
    utils.getByText("15", { exact: false });

    let utils2 = within(checkboxFields[1]);
    utils2.getByText(/^black-and-white negatives$/i);
    utils2.getByText("http://vocab.getty.edu/aat/300128343", { exact: false });
    utils2.getByText("25", { exact: false });
  });

  it("renders a close button", async () => {
    const user = userEvent.setup();
    renderComponent();
    const button = screen.getByTestId("close-button");
    expect(button);
    await user.click(button);
    expect(props.closeModal).toHaveBeenCalled();
  });
});
