import React from "react";
import TransferFileSetsModal from "./TransferFileSetsModal";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";
import { AuthProvider } from "@js/components/Auth/Auth";
import { mockWork } from "@js/components/Work/work.gql.mock.js";
import { screen } from "@testing-library/react";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import userEvent from "@testing-library/user-event";

let isModalOpen = true;

const handleClose = () => {
  isModalOpen = false;
};

const selectedFilesets = [
  mockWork.fileSets[0].id,
  mockWork.fileSets[1].id,
];

describe("Transfer file sets to another work modal", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(TransferFileSetsModal, {
      closeModal: handleClose,
      isVisible: isModalOpen,
      fromWorkId: mockWork.id,
      selectedFilesets: selectedFilesets,
      work: mockWork,
    });
    return renderWithRouterApollo(
      <AuthProvider>
        <Wrapped />
      </AuthProvider>,
      {
        mocks: [
          getCurrentUserMock,
        ],
      }
    );
  });

  it("renders transfer filesets form", async () => {
    expect(await screen.findByTestId("transfer-filesets-form"));
  });

  it("displays the number of selected filesets", async () => {
    expect(
      await screen.findByText(/Transferring 2 fileset\(s\)/)
    ).toBeInTheDocument();
  });

  it("displays the source work information", async () => {
    expect(
      await screen.findByText(/From Work:/)
    ).toBeInTheDocument();
    expect(screen.getByText(/Donohue_001/)).toBeInTheDocument();
  });

  it("shows transfer destination options", async () => {
    expect(
      await screen.findByText("Transfer to existing work")
    ).toBeInTheDocument();
    expect(screen.getByText("Create new work")).toBeInTheDocument();
  });

  it("defaults to existing work transfer option", async () => {
    const existingWorkRadio = await screen.findByDisplayValue("existing");
    expect(existingWorkRadio).toBeChecked();
  });

  it("shows accession number field when transferring to existing work", async () => {
    expect(
      await screen.findByTestId("accession-number")
    ).toBeInTheDocument();
  });

  it("shows new work fields when create new work is selected", async () => {
    const user = userEvent.setup();
    const newWorkRadio = await screen.findByDisplayValue("new");

    await user.click(newWorkRadio);

    expect(
      await screen.findByTestId("new-work-accession-number")
    ).toBeInTheDocument();
    expect(screen.getByTestId("new-work-title")).toBeInTheDocument();
  });

  it("shows preview checkbox", async () => {
    expect(
      await screen.findByText("Show preview of selected filesets")
    ).toBeInTheDocument();
  });

  it("displays preview when checkbox is checked", async () => {
    const user = userEvent.setup();
    const previewText = await screen.findByText(
      "Show preview of selected filesets"
    );
    const previewCheckbox = previewText.closest("label").querySelector("input[type='checkbox']");

    await user.click(previewCheckbox);

    expect(
      await screen.findByText("Selected Filesets:")
    ).toBeInTheDocument();
  });

  it("requires confirmation text to submit", async () => {
    const submitButton = await screen.findByTestId("submit-button");
    expect(submitButton).toBeDisabled();
  });
});
