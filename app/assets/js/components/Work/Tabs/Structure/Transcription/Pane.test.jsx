// WorkTabsStructureTranscriptionPane.test.js
import React from "react";
import { render, screen } from "@testing-library/react";
import WorkTabsStructureTranscriptionPane from "./Pane";

describe("WorkTabsStructureTranscriptionPane", () => {
  it("renders a textarea with annotation attributes and calls callback when content is a string", () => {
    const hasTranscriptionCallback = jest.fn();
    const annotation = {
      id: "ann-1",
      type: "transcription",
      status: "done",
      content: "This is the transcription.",
    };

    render(
      <WorkTabsStructureTranscriptionPane
        annotation={annotation}
        hasTranscriptionCallback={hasTranscriptionCallback}
      />,
    );

    const textarea = screen.getByRole("textbox");
    expect(textarea).toBeInTheDocument();
    expect(textarea).toHaveValue("This is the transcription.");
    expect(textarea).toHaveAttribute("data-annotation-id", "ann-1");
    expect(textarea).toHaveAttribute("data-annotation-type", "transcription");
    expect(textarea).toHaveAttribute("data-annotation-status", "done");

    expect(hasTranscriptionCallback).toHaveBeenCalledTimes(1);
    expect(hasTranscriptionCallback).toHaveBeenCalledWith(true);
  });

  it("shows generating overlay when status is in_progress and no content, without calling callback", () => {
    const hasTranscriptionCallback = jest.fn();
    const annotation = {
      id: "ann-2",
      type: "transcription",
      status: "in_progress",
      content: null,
    };

    render(
      <WorkTabsStructureTranscriptionPane
        annotation={annotation}
        hasTranscriptionCallback={hasTranscriptionCallback}
      />,
    );

    // Overlay text
    expect(screen.getByText("Generating transcription...")).toBeInTheDocument();

    // Textarea is still rendered but empty
    const textarea = screen.getByRole("textbox");
    expect(textarea).toBeInTheDocument();
    expect(textarea).toHaveValue("");
    expect(textarea).toHaveAttribute("data-annotation-status", "in_progress");

    // Callback should not be called because content is not a string
    expect(hasTranscriptionCallback).not.toHaveBeenCalled();
  });

  it("switches from generating state to showing textarea content and calls callback when content arrives", () => {
    const hasTranscriptionCallback = jest.fn();

    const initialAnnotation = {
      id: "ann-3",
      type: "transcription",
      status: "in_progress",
      content: null,
    };

    const { rerender } = render(
      <WorkTabsStructureTranscriptionPane
        annotation={initialAnnotation}
        hasTranscriptionCallback={hasTranscriptionCallback}
      />,
    );

    // Initially: overlay visible, textarea empty, no callback
    expect(screen.getByText("Generating transcription...")).toBeInTheDocument();
    const initialTextarea = screen.getByRole("textbox");
    expect(initialTextarea).toHaveValue("");
    expect(hasTranscriptionCallback).not.toHaveBeenCalled();

    // Now simulate "transcription finished" – annotation gains content and status changes
    const updatedAnnotation = {
      ...initialAnnotation,
      status: "done",
      content: "Final generated transcription",
    };

    rerender(
      <WorkTabsStructureTranscriptionPane
        annotation={updatedAnnotation}
        hasTranscriptionCallback={hasTranscriptionCallback}
      />,
    );

    // Overlay should be gone
    expect(
      screen.queryByText("Generating transcription..."),
    ).not.toBeInTheDocument();

    const textarea = screen.getByRole("textbox");
    expect(textarea).toBeInTheDocument();
    expect(textarea).toHaveValue("Final generated transcription");
    expect(textarea).toHaveAttribute("data-annotation-status", "done");

    expect(hasTranscriptionCallback).toHaveBeenCalledTimes(1);
    expect(hasTranscriptionCallback).toHaveBeenCalledWith(true);
  });
});
