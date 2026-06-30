// js/components/Work/Tabs/Structure/Transcription/Modal.test.jsx
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MockedProvider } from "@apollo/client/testing";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import {
  UPDATE_FILE_SET_ANNOTATION,
  UPSERT_FILE_SET_ANNOTATION,
  DELETE_FILE_SET_ANNOTATION,
} from "./transcription.gql";
import { GET_WORK } from "@js/components/Work/work.gql";

// --- Mocks ---

// Simple stub for CloverImage
jest.mock("@samvera/clover-iiif/image", () => {
  const React = require("react");
  return {
    __esModule: true,
    default: function CloverImageStub(props) {
      return <img data-testid="clover-image" src={props.src} alt="" />;
    },
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

// toast wrapper and download helper
jest.mock("@js/services/helpers", () => ({
  toastWrapper: jest.fn(),
  downloadBlob: jest.fn(),
}));

// Lets individual tests drive whether the mock Workflow renders an existing
// (saved) annotation or a from-scratch textarea with no annotation id.
const workflowState = {
  annotationId: "ann-1",
  defaultValue: "Existing transcription",
};

// Mock Workflow so it renders the textarea the modal is looking for, wiring
// hasTranscriptionCallback and onContentChange the same way the real
// Workflow/Pane pair does so the modal's dirty-state tracking works in tests.
jest.mock("@js/components/Work/Tabs/Structure/Transcription/Workflow", () => {
  const React = require("react");
  const { useEffect } = React;
  return {
    __esModule: true,
    default: function MockWorkflow({
      hasTranscriptionCallback,
      onContentChange,
    }) {
      const props = workflowState.annotationId
        ? { "data-annotation-id": workflowState.annotationId }
        : {};
      useEffect(() => {
        hasTranscriptionCallback?.();
      }, []);
      return (
        <textarea
          id="file-set-transcription-textarea"
          data-annotation-type="transcription"
          defaultValue={workflowState.defaultValue}
          onChange={
            onContentChange ? (e) => onContentChange(e.target.value) : undefined
          }
          {...props}
        />
      );
    },
  };
});

const { useWorkDispatch, useWorkState } =
  await import("@js/context/work-context");
const { toastWrapper } = await import("@js/services/helpers");
const { default: WorkTabsStructureTranscriptionModal } =
  await import("./Modal");

describe("WorkTabsStructureTranscriptionModal", () => {
  let mockDispatch;

  beforeEach(() => {
    jest.clearAllMocks();

    workflowState.annotationId = "ann-1";
    workflowState.defaultValue = "Existing transcription";

    mockDispatch = jest.fn();
    useWorkDispatch.mockReturnValue(mockDispatch);
    useWorkState.mockReturnValue({
      transcriptionModal: { fileSetId: "fs-123" },
      work: { id: "work-456" },
    });
  });

  const renderModal = ({ isActive = true, mocks = [] } = {}) => {
    return render(
      <MockedProvider mocks={mocks}>
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

  it("Save is disabled until the user edits the textarea", async () => {
    renderModal();

    const saveButton = await screen.findByRole("button", { name: /save/i });

    // Save stays disabled even after the textarea is found — no changes yet.
    await waitFor(() => expect(saveButton).toBeDisabled());

    // Simulate the user typing a change.
    const textarea = document.getElementById("file-set-transcription-textarea");
    fireEvent.change(textarea, { target: { value: "Edited transcription" } });

    await waitFor(() => expect(saveButton).not.toBeDisabled());
  });

  it("calls mutation and closes modal on successful save", async () => {
    const mutationMocks = [
      {
        request: {
          query: UPDATE_FILE_SET_ANNOTATION,
          variables: {
            annotationId: "ann-1",
            content: "Edited transcription",
          },
        },
        result: {
          data: {
            updateFileSetAnnotation: {
              id: "ann-1",
              content: "Edited transcription",
            },
          },
        },
      },
    ];

    renderModal({ mocks: mutationMocks });

    const saveButton = await screen.findByRole("button", { name: /save/i });

    // Edit the textarea to make Save active.
    const textarea = document.getElementById("file-set-transcription-textarea");
    fireEvent.change(textarea, { target: { value: "Edited transcription" } });
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

  it("upserts a new annotation when saving a transcription typed from scratch", async () => {
    workflowState.annotationId = null;
    workflowState.defaultValue = "";

    const mutationMocks = [
      {
        request: {
          query: UPSERT_FILE_SET_ANNOTATION,
          variables: {
            fileSetId: "fs-123",
            type: "transcription",
            content: "Brand new transcription",
          },
        },
        result: {
          data: {
            upsertFileSetAnnotation: {
              id: "ann-new",
              content: "Brand new transcription",
            },
          },
        },
      },
    ];

    renderModal({ mocks: mutationMocks });

    const saveButton = await screen.findByRole("button", { name: /save/i });

    // Type the transcription from scratch; Save stays disabled until there is
    // an edit, then the empty annotation id routes the save through upsert.
    const textarea = document.getElementById("file-set-transcription-textarea");
    fireEvent.change(textarea, {
      target: { value: "Brand new transcription" },
    });
    await waitFor(() => expect(saveButton).not.toBeDisabled());

    fireEvent.click(saveButton);

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

  it("does not offer Delete for an unsaved, from-scratch transcription", async () => {
    workflowState.annotationId = null;
    workflowState.defaultValue = "";

    renderModal();

    await screen.findByRole("button", { name: /save/i });

    expect(
      screen.queryByRole("button", { name: /delete transcription/i }),
    ).not.toBeInTheDocument();
  });

  it("shows error toast when mutation fails", async () => {
    const mutationMocks = [
      {
        request: {
          query: UPDATE_FILE_SET_ANNOTATION,
          variables: {
            annotationId: "ann-1",
            content: "Edited transcription",
          },
        },
        error: new Error("Boom"),
      },
    ];

    renderModal({ mocks: mutationMocks });

    const saveButton = await screen.findByRole("button", { name: /save/i });

    const textarea = document.getElementById("file-set-transcription-textarea");
    fireEvent.change(textarea, { target: { value: "Edited transcription" } });
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

  it("downloads transcription text when Download button is clicked", async () => {
    // downloadBlob is mocked via jest.mock("@js/services/helpers", …) above.
    // Assert it is called with a Blob and a filename derived from the file set.
    // We don't provide a GET_WORK mock here so the accession number is unavailable
    // and the filename falls back to the fileSetId ("fs-123").
    const { downloadBlob } = await import("@js/services/helpers");

    renderModal();

    const downloadButton = await screen.findByRole("button", {
      name: /download transcription/i,
    });
    fireEvent.click(downloadButton);

    expect(downloadBlob).toHaveBeenCalledWith(
      expect.any(Blob),
      "transcription-fs-123.txt",
    );
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
