// js/components/Work/Tabs/Structure/Transcription/Modal.test.jsx
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MockedProvider } from "@apollo/client/testing/react";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";
import { toastWrapper } from "@js/services/helpers";
import WorkTabsStructureTranscriptionModal from "./Modal";
import {
  UPDATE_FILE_SET_ANNOTATION,
  DELETE_FILE_SET_ANNOTATION,
} from "./transcription.gql";

// --- Mocks ---

// Simple stub for CloverImage
jest.mock("@samvera/clover-iiif/image", () => {
  const React = require("react");
  return function CloverImageStub(props) {
    return <img data-testid="clover-image" src={props.src} alt="" />;
  };
});

// Simple stub for Button and Notification
jest.mock("@nulib/design-system", () => {
  const React = require("react");
  return {
    Button: ({ children, ...props }) => <button {...props}>{children}</button>,
    Notification: ({ children, ...props }) => <div {...props}>{children}</div>,
  };
});

// Work context hooks
jest.mock("@js/context/work-context", () => ({
  useWorkDispatch: jest.fn(),
  useWorkState: jest.fn(),
}));

// toast wrapper
jest.mock("@js/services/helpers", () => ({
  toastWrapper: jest.fn(),
}));

// Mock Workflow so it renders the textarea the modal is looking for
jest.mock("./Workflow", () => {
  const React = require("react");
  return function MockWorkflow() {
    return (
      <textarea
        id="file-set-transcription-textarea"
        data-annotation-id="ann-1"
        data-annotation-type="transcription"
        defaultValue="Existing transcription"
      />
    );
  };
});

describe("WorkTabsStructureTranscriptionModal", () => {
  let mockDispatch;

  beforeEach(() => {
    jest.clearAllMocks();

    mockDispatch = jest.fn();
    useWorkDispatch.mockReturnValue(mockDispatch);
    useWorkState.mockReturnValue({
      transcriptionModal: { fileSetId: "fs-123" },
      work: { id: "work-456" },
    });
  });

  const renderModal = ({ isActive = true, mocks = [] } = {}) => {
    return render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <IIIFContext.Provider value="https://iiif.example/">
          <WorkTabsStructureTranscriptionModal isActive={isActive} />
        </IIIFContext.Provider>
      </MockedProvider>,
    );
  };

  it("renders an active modal with IIIF image", () => {
    renderModal();

    const image = screen.getByTestId("clover-image");
    expect(image).toBeInTheDocument();
    // Just sanity-check the prefix; full URL includes IIIF_SIZES
    expect(image.getAttribute("src")).toContain("https://iiif.example/");
    expect(image.getAttribute("src")).toContain("fs-123");
  });

  it("disables Save when textarea is not yet found", async () => {
    // The effect that finds the textarea runs after mount, so on first paint
    // Save may be disabled. We can at least assert it's a button and becomes
    // enabled once the textarea exists.
    renderModal();

    const saveButton = await screen.findByRole("button", { name: /save/i });
    // After the effect + mock Workflow render, it should be enabled:
    await waitFor(() => expect(saveButton).not.toBeDisabled());
  });

  it("calls mutation and closes modal on successful save", async () => {
    const mutationMocks = [
      {
        request: {
          query: UPDATE_FILE_SET_ANNOTATION,
          variables: {
            annotationId: "ann-1",
            content: "Existing transcription",
          },
        },
        result: {
          data: {
            updateFileSetAnnotation: {
              id: "ann-1",
              content: "Existing transcription",
            },
          },
        },
      },
    ];

    renderModal({ mocks: mutationMocks });

    const saveButton = await screen.findByRole("button", { name: /save/i });

    // Wait until textarea is found and Save enabled
    await waitFor(() => expect(saveButton).not.toBeDisabled());

    fireEvent.click(saveButton);

    // Wait for mutation + onCompleted to propagate
    await waitFor(() => {
      expect(toastWrapper).toHaveBeenCalledWith(
        "is-success",
        "Transcription successfully saved",
      );
    });

    expect(mockDispatch).toHaveBeenCalledWith({
      type: "toggleTranscriptionModal",
      fileSetId: null,
    });
  });

  it("shows error toast when mutation fails", async () => {
    const mutationMocks = [
      {
        request: {
          query: UPDATE_FILE_SET_ANNOTATION,
          variables: {
            annotationId: "ann-1",
            content: "Existing transcription",
          },
        },
        error: new Error("Boom"),
      },
    ];

    renderModal({ mocks: mutationMocks });

    const saveButton = await screen.findByRole("button", { name: /save/i });
    await waitFor(() => expect(saveButton).not.toBeDisabled());

    fireEvent.click(saveButton);

    await waitFor(() => {
      expect(toastWrapper).toHaveBeenCalledWith(
        "is-danger",
        "Error saving transcription: Boom",
      );
    });

    // Modal should NOT auto-close on error
    expect(mockDispatch).not.toHaveBeenCalledWith({
      type: "toggleTranscriptionModal",
      fileSetId: null,
    });
  });

  it("closes modal when clicking close icon and Cancel button", async () => {
    renderModal();

    const closeIcon = screen.getByLabelText(/close/i);
    fireEvent.click(closeIcon);

    expect(mockDispatch).toHaveBeenCalledWith({
      type: "toggleTranscriptionModal",
      fileSetId: null,
    });

    mockDispatch.mockClear();

    const cancelButton = await screen.findByRole("button", { name: /cancel/i });
    fireEvent.click(cancelButton);

    expect(mockDispatch).toHaveBeenCalledWith({
      type: "toggleTranscriptionModal",
      fileSetId: null,
    });
  });

  it("calls delete mutation and closes modal on successful delete", async () => {
    const mutationMocks = [
      {
        request: {
          query: DELETE_FILE_SET_ANNOTATION,
          variables: {
            annotationId: "ann-1",
          },
        },
        result: {
          data: {
            deleteFileSetAnnotation: {
              id: "ann-1",
              fileSetId: "fs-123",
            },
          },
        },
      },
    ];

    renderModal({ mocks: mutationMocks });

    const deleteButton = await screen.findByRole("button", {
      name: /delete transcription/i,
    });

    // Click delete to show confirmation
    fireEvent.click(deleteButton);

    // Verify confirmation notification appears
    expect(
      screen.getByText(/are you sure you want to delete this transcription/i),
    ).toBeInTheDocument();

    // Click "Yes, delete" to confirm
    const confirmButton = await screen.findByRole("button", {
      name: /yes, delete/i,
    });
    fireEvent.click(confirmButton);

    await waitFor(() => {
      expect(toastWrapper).toHaveBeenCalledWith(
        "is-success",
        "Transcription successfully deleted",
      );
    });

    expect(mockDispatch).toHaveBeenCalledWith({
      type: "toggleTranscriptionModal",
      fileSetId: null,
    });
  });

  it("shows error toast when delete mutation fails", async () => {
    const mutationMocks = [
      {
        request: {
          query: DELETE_FILE_SET_ANNOTATION,
          variables: {
            annotationId: "ann-1",
          },
        },
        error: new Error("Delete failed"),
      },
    ];

    renderModal({ mocks: mutationMocks });

    const deleteButton = await screen.findByRole("button", {
      name: /delete transcription/i,
    });

    // Click delete to show confirmation
    fireEvent.click(deleteButton);

    // Click "Yes, delete" to confirm
    const confirmButton = await screen.findByRole("button", {
      name: /yes, delete/i,
    });
    fireEvent.click(confirmButton);

    await waitFor(() => {
      expect(toastWrapper).toHaveBeenCalledWith(
        "is-danger",
        "Error deleting transcription: Delete failed",
      );
    });

    expect(mockDispatch).not.toHaveBeenCalledWith({
      type: "toggleTranscriptionModal",
      fileSetId: null,
    });
  });
});
