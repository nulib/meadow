// js/components/Work/Tabs/Structure/Transcription/Workflow.test.jsx
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MockedProvider } from "@apollo/client/testing";

import { TRANSCRIBE_FILE_SET } from "@js/components/Work/Tabs/Structure/Transcription/transcription.gql";
import { GET_WORK } from "@js/components/Work/work.gql";

// ---- Mocks ----

// useFileSetAnnotation hook
jest.mock("@js/hooks/useFileSetAnnotation", () => ({
  useFileSetAnnotation: jest.fn(),
}));

// toast wrapper
jest.mock("@js/services/helpers", () => ({
  toastWrapper: jest.fn(),
}));

// Design-system Button → simple <button>
jest.mock("@nulib/design-system", () => {
  const React = require("react");
  return {
    Button: ({ children, ...props }) => <button {...props}>{children}</button>,
    Notification: ({ children, ...props }) => <div {...props}>{children}</div>,
  };
});

// Pane component → simple div so we can assert props
jest.mock("@js/components/Work/Tabs/Structure/Transcription/Pane", () => {
  const React = require("react");
  return {
    __esModule: true,
    default: function MockPane({ annotation }) {
      return (
        <div
          data-testid="transcription-pane"
          data-annotation-id={annotation?.id || ""}
        />
      );
    },
  };
});

const { default: WorkTabsStructureTranscriptionWorkflow } =
  await import("./Workflow");
const { useFileSetAnnotation } = await import("@js/hooks/useFileSetAnnotation");
const { toastWrapper } = await import("@js/services/helpers");

describe("WorkTabsStructureTranscriptionWorkflow", () => {
  const fileSetId = "fs-123";
  const workId = "work-456";

  const baseWork = {
    id: workId,
    fileSets: [
      {
        id: fileSetId,
        annotations: [],
        __typename: "FileSet",
      },
    ],
    __typename: "Work",
  };

  const renderWorkflow = ({ mocks, hookData, isActive = true } = {}) => {
    // Default: no fileSet annotation from hook
    useFileSetAnnotation.mockReturnValue(
      hookData || { data: { fileSetAnnotation: null } },
    );

    return render(
      <MockedProvider mocks={mocks || []} addTypename={false}>
        <WorkTabsStructureTranscriptionWorkflow
          fileSetId={fileSetId}
          workId={workId}
          isActive={isActive}
          hasTranscriptionCallback={jest.fn()}
        />
      </MockedProvider>,
    );
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("renders the Generate Transcription button when there is no annotation", async () => {
    const workMocks = [
      {
        request: { query: GET_WORK, variables: { id: workId } },
        result: { data: { work: baseWork } },
      },
      {
        request: { query: GET_WORK, variables: { id: workId } },
        result: { data: { work: baseWork } },
      },
    ];

    const { container } = renderWorkflow({ mocks: workMocks });

    const button = await screen.findByRole("button", {
      name: /generate transcription/i,
    });

    expect(button).toBeInTheDocument();

    // Wrapper should NOT have the data-annotation attribute yet
    const wrapper = container.firstChild;
    expect(wrapper).not.toHaveAttribute("data-annotation");
  });

  it("calls TRANSCRIBE_FILE_SET and shows a success toast when button is clicked", async () => {
    const workMocks = [
      // initial GET_WORK
      {
        request: {
          query: GET_WORK,
          variables: { id: workId },
        },
        result: {
          data: {
            work: baseWork,
          },
        },
      },
      // refetch after mutation
      {
        request: {
          query: GET_WORK,
          variables: { id: workId },
        },
        result: {
          data: {
            work: baseWork,
          },
        },
      },
      // mutation: TRANSCRIBE_FILE_SET
      {
        request: {
          query: TRANSCRIBE_FILE_SET,
          variables: { fileSetId },
        },
        result: {
          data: {
            transcribeFileSet: {
              id: fileSetId,
            },
          },
        },
      },
    ];

    renderWorkflow({ mocks: workMocks });

    const button = await screen.findByRole("button", {
      name: /generate transcription/i,
    });

    fireEvent.click(button);

    await waitFor(() => {
      expect(toastWrapper).toHaveBeenCalledWith(
        "is-success",
        "Generating transcription",
      );
    });

    // Still no Pane yet (annotation will appear on a subsequent fetch)
    expect(screen.queryByTestId("transcription-pane")).not.toBeInTheDocument();
  });

  it("renders GraphQL errors from TRANSCRIBE_FILE_SET when transcription fails", async () => {
    const details = { model: "is invalid" };
    const workMocks = [
      {
        request: {
          query: GET_WORK,
          variables: { id: workId },
        },
        result: {
          data: {
            work: baseWork,
          },
        },
      },
      {
        request: {
          query: GET_WORK,
          variables: { id: workId },
        },
        result: {
          data: {
            work: baseWork,
          },
        },
      },
      {
        request: {
          query: TRANSCRIBE_FILE_SET,
          variables: { fileSetId },
        },
        result: {
          data: {
            transcribeFileSet: null,
          },
          errors: [
            {
              message: "Could not transcribe file_set",
              details,
              path: ["transcribeFileSet"],
            },
          ],
        },
      },
    ];

    renderWorkflow({ mocks: workMocks });

    const button = await screen.findByRole("button", {
      name: /generate transcription/i,
    });

    fireEvent.click(button);

    await waitFor(() => {
      expect(toastWrapper).toHaveBeenCalledWith(
        "is-danger",
        expect.stringMatching(
          /Could not transcribe file set.*Model:.*is invalid/i,
        ),
      );
    });
    const toastMessage = toastWrapper.mock.calls.find(
      ([type]) => type === "is-danger",
    )?.[1];
    expect(toastMessage).toBe(
      "Could not transcribe file set — Model: is invalid",
    );
  });

  it("renders Pane when an annotation already exists", async () => {
    const completedAnnotation = {
      id: "ann-1",
      status: "completed",
      type: "transcription",
      content: "Hello world",
      __typename: "Annotation",
    };

    const workMocks = [
      {
        request: {
          query: GET_WORK,
          variables: { id: workId },
        },
        result: {
          data: {
            work: {
              ...baseWork,
              fileSets: [
                {
                  id: fileSetId,
                  annotations: [completedAnnotation],
                  __typename: "FileSet",
                },
              ],
            },
          },
        },
      },
    ];

    const hookData = {
      data: {
        fileSetAnnotation: completedAnnotation,
      },
    };

    const { container } = renderWorkflow({ mocks: workMocks, hookData });

    const pane = await screen.findByTestId("transcription-pane");
    expect(pane).toBeInTheDocument();
    expect(pane).toHaveAttribute("data-annotation-id", "ann-1");

    // Wrapper div should also reflect the annotation id
    const wrapper = container.firstChild;
    expect(wrapper).toHaveAttribute("data-annotation", "ann-1");

    // No "Generate Transcription" button when we already have an annotation
    expect(
      screen.queryByRole("button", { name: /generate transcription/i }),
    ).not.toBeInTheDocument();
  });
});
